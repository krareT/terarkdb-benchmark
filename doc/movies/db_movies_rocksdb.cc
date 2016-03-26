// Copyright (c) 2011 The LevelDB Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file. See the AUTHORS file for names of contributors.

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <sstream>
#include <vector>

#include <iostream>
#include <fstream>
#include <string.h>

#include "port/port.h"
#include "util/crc32c.h"
#include "util/histogram.h"
#include "util/mutexlock.h"
#include "util/random.h"
#include "util/testutil.h"

#include "rocksdb/db.h"
#include "rocksdb/env.h"
#include "rocksdb/cache.h"
#include "rocksdb/options.h"
#include "rocksdb/table.h"
#include "rocksdb/filter_policy.h"

// Comma-separated list of operations to run in the specified order
//   Actual benchmarks:
//      fillseq       -- write N values in sequential key order in async mode
//      fillrandom    -- write N values in random key order in async mode
//      overwrite     -- overwrite N values in random key order in async mode
//      fillsync      -- write N/100 values in random key order in sync mode
//      fill100K      -- write N/1000 100K values in random order in async mode
//      deleteseq     -- delete N keys in sequential order
//      deleterandom  -- delete N keys in random order
//      readseq       -- read N times sequentially
//      readreverse   -- read N times in reverse order
//      readrandom    -- read N times in random order
//      readmissing   -- read N missing keys in random order
//      readhot       -- read N times in random order from 1% section of DB
//      seekrandom    -- N random seeks
//      crc32c        -- repeated crc32c of 4K of data
//      acquireload   -- load N*1000 times
//   Meta operations:
//      compact     -- Compact the entire DB
//      stats       -- Print DB stats
//      sstables    -- Print sstable info
//      heapprofile -- Dump a heap profile (if supported by this port)
static const char* FLAGS_benchmarks =
    "fillseq,"
    "deleteseq,"
    "fillseq,"
    "deleterandom,"
    "fillrandom,"
    "deleteseq,"
    "fillrandom,"
    "deleterandom,"
    "fillseqsync,"
    "fillrandsync,"
    "fillseq,"
    "fillseqbatch,"
    "fillrandom,"
    "fillrandbatch,"
    "overwrite,"
    "readrandom,"
#if 0
    "readrandom,"  // Extra run to allow previous compactions to quiesce
#endif
    "readseq,"
    "readreverse,"
#if 0
    "compact,"
    "readrandom,"
    "readseq,"
    "readreverse,"
    "fill100K,"
    "crc32c,"
    "snappycomp,"
    "snappyuncomp,"
    "acquireload,"
#endif
    ;

// Number of key/values to place in database
static int FLAGS_num = 1000000;

// Number of read operations to do.  If negative, do FLAGS_num reads.
static int FLAGS_reads = -1;

// Number of concurrent threads to run.
static int FLAGS_threads = 1;

// Size of each value
static int FLAGS_value_size = 100;

static enum rocksdb::CompressionType FLAGS_compression_type =
    rocksdb::kSnappyCompression;

static int FLAGS_min_level_to_compress = 0;

static int FLAGS_num_levels = 7;


// Arrange to generate values that shrink to this fraction of
// their original size after compression
static double FLAGS_compression_ratio = 0.5;

// Print histogram of operation timings
static bool FLAGS_histogram = false;

// Number of bytes to buffer in memtable before compacting
// (initialized to default value by "main")
static long FLAGS_write_buffer_size = 0;

// Number of bytes to use as a cache of uncompressed data.
// Negative means use default settings.
static long FLAGS_cache_size = -1;

// Maximum number of files to keep open at the same time (use default if == 0)
static int FLAGS_open_files = 0;

// Bloom filter bits per key.
// Negative means use default settings.
static int FLAGS_bloom_bits = -1;

// If true, do not destroy the existing database.  If you set this
// flag and also specify a benchmark that wants a fresh database, that
// benchmark will fail.
static bool FLAGS_use_existing_db = false;

// Use the db with the following name.
static const char* FLAGS_db = NULL;
static const char* FLAGS_resource_data = NULL;

static int *shuff = NULL;

namespace leveldb {

namespace {

// Helper for quickly generating random data.
class RandomGenerator {
 private:
  std::string data_;
  int pos_;

 public:
  RandomGenerator() {
    // We use a limited amount of data over and over again and ensure
    // that it is larger than the compression window (32KB), and also
    // large enough to serve all typical value sizes we want to write.
    Random rnd(301);
    std::string piece;
    while (data_.size() < 536870912) {
      // Add a short fragment that is as compressible as specified
      // by FLAGS_compression_ratio.
      test::CompressibleString(&rnd, FLAGS_compression_ratio, 100, &piece);
      data_.append(piece);
    }
    pos_ = 0;
  }

  rocksdb::Slice Generate(int len) {
    if (pos_ + len > data_.size()) {
      pos_ = 0;
      assert(len < data_.size());
    }
    pos_ += len;
    return rocksdb::Slice(data_.data() + pos_ - len, len);
  }
};

static rocksdb::Slice TrimSpace(rocksdb::Slice s) {
  int start = 0;
  while (start < s.size() && isspace(s[start])) {
    start++;
  }
  int limit = s.size();
  while (limit > start && isspace(s[limit-1])) {
    limit--;
  }
  return rocksdb::Slice(s.data() + start, limit - start);
}

static void AppendWithSpace(std::string* str, rocksdb::Slice msg) {
  if (msg.empty()) return;
  if (!str->empty()) {
    str->push_back(' ');
  }
  str->append(msg.data(), msg.size());
}


class Stats {
 private:
  double start_;
  double finish_;
  double seconds_;
  int done_;
  int next_report_;
  int64_t bytes_;
  double last_op_finish_;
  Histogram hist_;
  std::string message_;

 public:
  Stats() { Start(); }

  void Start() {
    next_report_ = 100;
    last_op_finish_ = start_;
    hist_.Clear();
    done_ = 0;
    bytes_ = 0;
    seconds_ = 0;
    start_ = Env::Default()->NowMicros();
    finish_ = start_;
    message_.clear();
  }

  void Merge(const Stats& other) {
    hist_.Merge(other.hist_);
    done_ += other.done_;
    bytes_ += other.bytes_;
    seconds_ += other.seconds_;
    if (other.start_ < start_) start_ = other.start_;
    if (other.finish_ > finish_) finish_ = other.finish_;

    // Just keep the messages from one thread
    if (message_.empty()) message_ = other.message_;
  }

  void Stop() {
    finish_ = Env::Default()->NowMicros();
    seconds_ = (finish_ - start_) * 1e-6;
  }

  void AddMessage(rocksdb::Slice msg) {
    AppendWithSpace(&message_, msg);
  }

  void FinishedSingleOp() {
    if (FLAGS_histogram) {
      double now = Env::Default()->NowMicros();
      double micros = now - last_op_finish_;
      hist_.Add(micros);
      if (micros > 20000) {
        fprintf(stderr, "long op: %.1f micros%30s\r", micros, "");
        fflush(stderr);
      }
      last_op_finish_ = now;
    }

    done_++;
    if (done_ >= next_report_) {
      if      (next_report_ < 1000)   next_report_ += 100;
      else if (next_report_ < 5000)   next_report_ += 500;
      else if (next_report_ < 10000)  next_report_ += 1000;
      else if (next_report_ < 50000)  next_report_ += 5000;
      else if (next_report_ < 100000) next_report_ += 10000;
      else if (next_report_ < 500000) next_report_ += 50000;
      else                            next_report_ += 100000;
      fprintf(stderr, "... finished %d ops%30s\r", done_, "");
      fflush(stderr);
    }
  }

  void AddBytes(int64_t n) {
    bytes_ += n;
  }

  void Report(const rocksdb::Slice& name) {
    // Pretend at least one op was done in case we are running a benchmark
    // that does not call FinishedSingleOp().
    if (done_ < 1) done_ = 1;

    std::string extra;
    if (bytes_ > 0) {
      // Rate is computed on actual elapsed time, not the sum of per-thread
      // elapsed times.
      double elapsed = (finish_ - start_) * 1e-6;
      char rate[100];
      snprintf(rate, sizeof(rate), "%6.1f MB/s",
               (bytes_ / 1048576.0) / elapsed);
      extra = rate;
    }
    AppendWithSpace(&extra, message_);

    fprintf(stdout, "%-12s : %11.3f micros/op;%s%s\n",
            name.ToString().c_str(),
            seconds_ * 1e6 / done_,
            (extra.empty() ? "" : " "),
            extra.c_str());
    if (FLAGS_histogram) {
      fprintf(stdout, "Microseconds per op:\n%s\n", hist_.ToString().c_str());
    }
    fflush(stdout);
  }
};

// State shared by all concurrent executions of the same benchmark.
struct SharedState {
  port::Mutex mu;
  port::CondVar cv;
  int total;

  // Each thread goes through the following states:
  //    (1) initializing
  //    (2) waiting for others to be initialized
  //    (3) running
  //    (4) done

  int num_initialized;
  int num_done;
  bool start;

  SharedState() : cv(&mu) { }
};

// Per-thread state for concurrent executions of the same benchmark.
struct ThreadState {
  int tid;             // 0..n-1 when running in n threads
  Random rand;         // Has different seeds for different threads
  Stats stats;
  SharedState* shared;

  ThreadState(int index)
      : tid(index),
        rand(1000 + index) {
  }
};

}  // namespace

class Benchmark {
 private:
  std::shared_ptr<rocksdb::Cache> cache_;
  std::shared_ptr<rocksdb::Cache> compressed_cache_;
  std::shared_ptr<const rocksdb::FilterPolicy> filter_policy_;
  rocksdb::DB* db_;

  std::vector<std::string> allkeys_;

  int num_;
  int value_size_;
  int entries_per_batch_;
  rocksdb::WriteOptions write_options_;
  int reads_;
  int heap_counter_;

  void PrintHeader() {
    const int kKeySize = 16;
    PrintEnvironment();
    fprintf(stdout, "Keys:       %d bytes each\n", kKeySize);
    fprintf(stdout, "Values:     %d bytes each (%d bytes after compression)\n",
            FLAGS_value_size,
            static_cast<int>(FLAGS_value_size * FLAGS_compression_ratio + 0.5));
    fprintf(stdout, "Entries:    %d\n", num_);
    fprintf(stdout, "RawSize:    %.1f MB (estimated)\n",
            ((static_cast<int64_t>(kKeySize + FLAGS_value_size) * num_)
             / 1048576.0));
    fprintf(stdout, "FileSize:   %.1f MB (estimated)\n",
            (((kKeySize + FLAGS_value_size * FLAGS_compression_ratio) * num_)
             / 1048576.0));
    PrintWarnings();
    fprintf(stdout, "------------------------------------------------\n");
  }

  void PrintWarnings() {
#if defined(__GNUC__) && !defined(__OPTIMIZE__)
    fprintf(stdout,
            "WARNING: Optimization is disabled: benchmarks unnecessarily slow\n"
            );
#endif
#ifndef NDEBUG
    fprintf(stdout,
            "WARNING: Assertions are enabled; benchmarks unnecessarily slow\n");
#endif

    // See if snappy is working by attempting to compress a compressible string
    const char text[] = "yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";
    std::string compressed;
    if (!port::Snappy_Compress(text, sizeof(text), &compressed)) {
      fprintf(stdout, "WARNING: Snappy compression is not enabled\n");
    } else if (compressed.size() >= sizeof(text)) {
      fprintf(stdout, "WARNING: Snappy compression is not effective\n");
    }
  }

  void PrintEnvironment() {
    fprintf(stdout, "RocksDB:    version %d.%d\n",
            rocksdb::kMajorVersion, rocksdb::kMinorVersion);
    fprintf(stderr, "RocksDB:    version %d.%d\n",
            rocksdb::kMajorVersion, rocksdb::kMinorVersion);

#if defined(__linux)
    time_t now = time(NULL);
    fprintf(stderr, "Date:       %s", ctime(&now));  // ctime() adds newline

    FILE* cpuinfo = fopen("/proc/cpuinfo", "r");
    if (cpuinfo != NULL) {
      char line[1000];
      int num_cpus = 0;
      std::string cpu_type;
      std::string cache_size;
      while (fgets(line, sizeof(line), cpuinfo) != NULL) {
        const char* sep = strchr(line, ':');
        if (sep == NULL) {
          continue;
        }
        rocksdb::Slice key = TrimSpace(rocksdb::Slice(line, sep - 1 - line));
        rocksdb::Slice val = TrimSpace(rocksdb::Slice(sep + 1));
        if (key == "model name") {
          ++num_cpus;
          cpu_type = val.ToString();
        } else if (key == "cache size") {
          cache_size = val.ToString();
        }
      }
      fclose(cpuinfo);
      fprintf(stderr, "CPU:        %d * %s\n", num_cpus, cpu_type.c_str());
      fprintf(stderr, "CPUCache:   %s\n", cache_size.c_str());
    }
#endif
  }

 public:
  Benchmark()
  : cache_(FLAGS_cache_size >= 0 ? rocksdb::NewLRUCache(FLAGS_cache_size) : NULL),
    filter_policy_(FLAGS_bloom_bits >= 0
                    ? rocksdb::NewBloomFilterPolicy(FLAGS_bloom_bits, false)
                    : NULL),
    db_(NULL),
    num_(FLAGS_num),
    value_size_(FLAGS_value_size),
    entries_per_batch_(1),
    reads_(FLAGS_reads < 0 ? FLAGS_num : FLAGS_reads),
    heap_counter_(0) {
    std::vector<std::string> files;
    Env::Default()->GetChildren(FLAGS_db, &files);
    for (int i = 0; i < files.size(); i++) {
      if (rocksdb::Slice(files[i]).starts_with("heap-")) {
        Env::Default()->DeleteFile(std::string(FLAGS_db) + "/" + files[i]);
      }
    }
    if (!FLAGS_use_existing_db) {
      rocksdb::DestroyDB(FLAGS_db, rocksdb::Options());
    }
  }

  ~Benchmark() {
    allkeys_.clear();
    delete db_;
  }

  void Run() {
    PrintHeader();
    std::cout << " Run() " << std::endl;
    Open();

    const char* benchmarks = FLAGS_benchmarks;
    while (benchmarks != NULL) {
      const char* sep = strchr(benchmarks, ',');
      rocksdb::Slice name;
      if (sep == NULL) {
        name = benchmarks;
        benchmarks = NULL;
      } else {
        name = rocksdb::Slice(benchmarks, sep - benchmarks);
        benchmarks = sep + 1;
      }

      // Reset parameters that may be overriddden bwlow
      num_ = FLAGS_num;
      reads_ = (FLAGS_reads < 0 ? FLAGS_num : FLAGS_reads);
      value_size_ = FLAGS_value_size;
      entries_per_batch_ = 1;
      write_options_ = rocksdb::WriteOptions();

      void (Benchmark::*method)(ThreadState*) = NULL;
      bool fresh_db = false;
      int num_threads = FLAGS_threads;

      if (name == rocksdb::Slice("fillseq")) {
        fresh_db = true;
        method = &Benchmark::WriteSeq;
      } else if (name == rocksdb::Slice("fillseqbatch")) {
        fresh_db = true;
        entries_per_batch_ = 1000;
        method = &Benchmark::WriteSeq;
      } else if (name == rocksdb::Slice("fillrandbatch")) {
        fresh_db = true;
        entries_per_batch_ = 1000;
        method = &Benchmark::WriteRandom;
      } else if (name == rocksdb::Slice("fillrandom")) {
        fresh_db = true;
        method = &Benchmark::WriteRandom;
      } else if (name == rocksdb::Slice("overwrite")) {
        fresh_db = false;
        method = &Benchmark::WriteRandom;
      } else if (name == rocksdb::Slice("fillseqsync")) {
        fresh_db = true;
#if 1
        num_ /= 1000;
		if (num_<10) num_=10;
#endif
        write_options_.sync = true;
        method = &Benchmark::WriteSeq;
      } else if (name == rocksdb::Slice("fillrandsync")) {
        fresh_db = true;
#if 1
        num_ /= 1000;
		if (num_<10) num_=10;
#endif
        write_options_.sync = true;
        method = &Benchmark::WriteRandom;
      } else if (name == rocksdb::Slice("fill100K")) {
        fresh_db = true;
        num_ /= 1000;
        value_size_ = 100 * 1000;
        method = &Benchmark::WriteRandom;
      } else if (name == rocksdb::Slice("readseq")) {
        method = &Benchmark::ReadSequential;
      } else if (name == rocksdb::Slice("readreverse")) {
        method = &Benchmark::ReadReverse;
      } else if (name == rocksdb::Slice("readrandom")) {
        method = &Benchmark::ReadRandom;
        
        std::ifstream ifs(FLAGS_resource_data);
        std::string str;
        std::string key1;
        std::string key2;
        int64_t keynum = 0;

        while(getline(ifs, str)) {
            if (str.find("product/productId:") == 0) {
                key1 = str.substr(19);
                continue;
            }
            if (str.find("review/userId:") == 0) {
                key2 = str.substr(15);
                continue;
            }
            if (str == "") {
                allkeys_.push_back(key1 + " " + key2);
                continue;
            }
        }

        assert(allkeys_.size() == FLAGS_num);

      } else if (name == rocksdb::Slice("readmissing")) {
        method = &Benchmark::ReadMissing;
      } else if (name == rocksdb::Slice("seekrandom")) {
        method = &Benchmark::SeekRandom;
      } else if (name == rocksdb::Slice("readhot")) {
        method = &Benchmark::ReadHot;
      } else if (name == rocksdb::Slice("readrandomsmall")) {
        reads_ /= 1000;
        method = &Benchmark::ReadRandom;
      } else if (name == rocksdb::Slice("deleteseq")) {
        method = &Benchmark::DeleteSeq;
      } else if (name == rocksdb::Slice("deleterandom")) {
        method = &Benchmark::DeleteRandom;
      } else if (name == rocksdb::Slice("readwhilewriting")) {
        num_threads++;  // Add extra thread for writing
        method = &Benchmark::ReadWhileWriting;

        std::ifstream ifs(FLAGS_resource_data);
        std::string str;
        std::string key1;
        std::string key2;
        int64_t keynum = 0;

        while(getline(ifs, str)) {
            if (str.find("product/productId:") == 0) {
                key1 = str.substr(19);
                continue;
            }
            if (str.find("review/userId:") == 0) {
                key2 = str.substr(15);
                continue;
            }
            if (str == "") {
                allkeys_.push_back(key1 + " " + key2);
                continue;
            }
        }

        assert(allkeys_.size() == FLAGS_num);

      } else if (name == rocksdb::Slice("readwritedel")) {
        method = &Benchmark::ReadWriteDel;

        std::ifstream ifs(FLAGS_resource_data);
        std::string str;
        std::string key1;
        std::string key2;
        int64_t keynum = 0;

        while(getline(ifs, str)) {
            if (str.find("product/productId:") == 0) {
                key1 = str.substr(19);
                continue;
            }
            if (str.find("review/userId:") == 0) {
                key2 = str.substr(15);
                continue;
            }
            if (str == "") {
                allkeys_.push_back(key1 + " " + key2);
                continue;
            }
        }

        assert(allkeys_.size() == FLAGS_num);

      } else if (name == rocksdb::Slice("compact")) {
        method = &Benchmark::Compact;
      } else if (name == rocksdb::Slice("crc32c")) {
        method = &Benchmark::Crc32c;
      } else if (name == rocksdb::Slice("acquireload")) {
        method = &Benchmark::AcquireLoad;
      } else if (name == rocksdb::Slice("snappycomp")) {
        method = &Benchmark::SnappyCompress;
      } else if (name == rocksdb::Slice("snappyuncomp")) {
        method = &Benchmark::SnappyUncompress;
      } else if (name == rocksdb::Slice("heapprofile")) {
        HeapProfile();
      } else if (name == rocksdb::Slice("stats")) {
        PrintStats("leveldb.stats");
      } else if (name == rocksdb::Slice("sstables")) {
        PrintStats("leveldb.sstables");
      } else {
        if (name != rocksdb::Slice()) {  // No error message for empty name
          fprintf(stderr, "unknown benchmark '%s'\n", name.ToString().c_str());
        }
      }

      if (fresh_db) {
        if (FLAGS_use_existing_db) {
/*
          fprintf(stdout, "%-12s : skipped (--use_existing_db is true)\n",
                  name.ToString().c_str());
          method = NULL;
*/
        } else {
          delete db_;
          db_ = NULL;
          rocksdb::DestroyDB(FLAGS_db, rocksdb::Options());
	  std::cout << " frehs_db==> DestroyDB" << std::endl;
          Open();
        }
      }

      if (method != NULL) {
        RunBenchmark(num_threads, name, method);
      }
    }
  }

 private:
  struct ThreadArg {
    Benchmark* bm;
    SharedState* shared;
    ThreadState* thread;
    void (Benchmark::*method)(ThreadState*);
  };

  static void ThreadBody(void* v) {
    ThreadArg* arg = reinterpret_cast<ThreadArg*>(v);
    SharedState* shared = arg->shared;
    ThreadState* thread = arg->thread;
    {
      MutexLock l(&shared->mu);
      shared->num_initialized++;
      if (shared->num_initialized >= shared->total) {
        shared->cv.SignalAll();
      }
      while (!shared->start) {
        shared->cv.Wait();
      }
    }

    thread->stats.Start();
    (arg->bm->*(arg->method))(thread);
    thread->stats.Stop();

    {
      MutexLock l(&shared->mu);
      shared->num_done++;
      if (shared->num_done >= shared->total) {
        shared->cv.SignalAll();
      }
    }
  }

  void RunBenchmark(int n, rocksdb::Slice name,
                    void (Benchmark::*method)(ThreadState*)) {
    SharedState shared;
    shared.total = n;
    shared.num_initialized = 0;
    shared.num_done = 0;
    shared.start = false;

    ThreadArg* arg = new ThreadArg[n];
    for (int i = 0; i < n; i++) {
      arg[i].bm = this;
      arg[i].method = method;
      arg[i].shared = &shared;
      arg[i].thread = new ThreadState(i);
      arg[i].thread->shared = &shared;
      Env::Default()->StartThread(ThreadBody, &arg[i]);
    }

    shared.mu.Lock();
    while (shared.num_initialized < n) {
      shared.cv.Wait();
    }

    shared.start = true;
    shared.cv.SignalAll();
    while (shared.num_done < n) {
      shared.cv.Wait();
    }
    shared.mu.Unlock();

    for (int i = 1; i < n; i++) {
      arg[0].thread->stats.Merge(arg[i].thread->stats);
    }
    arg[0].thread->stats.Report(name);

    for (int i = 0; i < n; i++) {
      delete arg[i].thread;
    }
    delete[] arg;
  }

  void Crc32c(ThreadState* thread) {
    // Checksum about 500MB of data total
    const int size = 4096;
    const char* label = "(4K per op)";
    std::string data(size, 'x');
    int64_t bytes = 0;
    uint32_t crc = 0;
    while (bytes < 500 * 1048576) {
      crc = crc32c::Value(data.data(), size);
      thread->stats.FinishedSingleOp();
      bytes += size;
    }
    // Print so result is not dead
    fprintf(stderr, "... crc=0x%x\r", static_cast<unsigned int>(crc));

    thread->stats.AddBytes(bytes);
    thread->stats.AddMessage(label);
  }

  void AcquireLoad(ThreadState* thread) {
    int dummy;
    port::AtomicPointer ap(&dummy);
    int count = 0;
    void *ptr = NULL;
    thread->stats.AddMessage("(each op is 1000 loads)");
    while (count < 100000) {
      for (int i = 0; i < 1000; i++) {
        ptr = ap.Acquire_Load();
      }
      count++;
      thread->stats.FinishedSingleOp();
    }
    if (ptr == NULL) exit(1); // Disable unused variable warning.
  }

  void SnappyCompress(ThreadState* thread) {
    RandomGenerator gen;
    rocksdb::Slice input = gen.Generate(rocksdb::BlockBasedTableOptions().block_size);
    int64_t bytes = 0;
    int64_t produced = 0;
    bool ok = true;
    std::string compressed;
    while (ok && bytes < 1024 * 1048576) {  // Compress 1G
      ok = port::Snappy_Compress(input.data(), input.size(), &compressed);
      produced += compressed.size();
      bytes += input.size();
      thread->stats.FinishedSingleOp();
    }

    if (!ok) {
      thread->stats.AddMessage("(snappy failure)");
    } else {
      char buf[100];
      snprintf(buf, sizeof(buf), "(output: %.1f%%)",
               (produced * 100.0) / bytes);
      thread->stats.AddMessage(buf);
      thread->stats.AddBytes(bytes);
    }
  }

  void SnappyUncompress(ThreadState* thread) {
    RandomGenerator gen;
    rocksdb::Slice input = gen.Generate(rocksdb::BlockBasedTableOptions().block_size);
    std::string compressed;
    bool ok = port::Snappy_Compress(input.data(), input.size(), &compressed);
    int64_t bytes = 0;
    char* uncompressed = new char[input.size()];
    while (ok && bytes < 1024 * 1048576) {  // Compress 1G
      ok =  port::Snappy_Uncompress(compressed.data(), compressed.size(),
                                    uncompressed);
      bytes += input.size();
      thread->stats.FinishedSingleOp();
    }
    delete[] uncompressed;

    if (!ok) {
      thread->stats.AddMessage("(snappy failure)");
    } else {
      thread->stats.AddBytes(bytes);
    }
  }

  void Open() {
    assert(db_ == nullptr);
    rocksdb::Options options;

    options.create_if_missing = !FLAGS_use_existing_db;
    options.write_buffer_size = FLAGS_write_buffer_size;
    std::cout << options.write_buffer_size << std::endl;

    rocksdb::BlockBasedTableOptions block_based_options;
    block_based_options.index_type = rocksdb::BlockBasedTableOptions::kBinarySearch;
    block_based_options.block_cache = cache_;
    block_based_options.filter_policy = filter_policy_;
    options.table_factory.reset(
		    NewBlockBasedTableFactory(block_based_options));
  
    options.compression = FLAGS_compression_type;
    if (FLAGS_min_level_to_compress >= 0) {
      assert(FLAGS_min_level_to_compress <= FLAGS_num_levels);
      options.compression_per_level.resize(FLAGS_num_levels);
      for (int i = 0; i < FLAGS_min_level_to_compress; i++) {
        options.compression_per_level[i] = FLAGS_compression_type;
        //options.compression_per_level[i] = rocksdb::kNoCompression;
      }
      for (int i = FLAGS_min_level_to_compress;
           i < FLAGS_num_levels; i++) {
        options.compression_per_level[i] = FLAGS_compression_type;
        //options.compression_per_level[i] = rocksdb::kNoCompression;
      }
    }

    std::cout << "Create database " << FLAGS_db << std::endl;
    rocksdb::Status s = rocksdb::DB::Open(options, FLAGS_db, &db_);
    if (!s.ok()) {
      fprintf(stderr, "open error: %s\n", s.ToString().c_str());
      exit(1);
    }
  }

  void WriteSeq(ThreadState* thread) {
    DoWrite(thread, true);
  }

  void WriteRandom(ThreadState* thread) {
    DoWrite(thread, false);
  }

  void DoWrite(ThreadState* thread, bool seq) {
    if (num_ != FLAGS_num) {
      char msg[100];
      snprintf(msg, sizeof(msg), "(%d ops)", num_);
      thread->stats.AddMessage(msg);
    }

    if (!seq)
	  thread->rand.Shuffle(shuff, num_);

    std::ifstream ifs(FLAGS_resource_data);  
    std::string str;

    std::string key1; 
    std::string key2; 
    std::string key; 
    std::string value; 
    rocksdb::Status s;	

    while(getline(ifs, str)) {
	    if (str.find("product/productId:") == 0) {
		    key1 = str.substr(19);
            continue;
	    }
	    if (str.find("review/userId:") == 0) {
		    key2 = str.substr(15);
            continue;
	    }
	    if (str.find("review/profileName:") == 0) {
		    value += str.substr(20);
		    value += " ";
            continue;
	    }
	    if (str.find("review/helpfulness:") == 0) {
		    value += str.substr(20);
		    value += " ";
            continue;
	    }
	    if (str.find("review/score:") == 0) {
		    value += str.substr(14);
		    value += " ";
            continue;
	    }
	    if (str.find("review/time:") == 0) {
		    value += str.substr(13);
		    value += " ";
            continue;
	    }
	    if (str.find("review/summary:") == 0) {
		    value += str.substr(16);
		    value += " ";
            continue;
	    }
	    if (str.find("review/text:") == 0) {
		    value += str.substr(13);
            continue;
	    }

	    if (str == "") {
            key = key1 + " " + key2;
		    s = db_->Put(write_options_, key, value);
		    if (!s.ok()) {
			    fprintf(stderr, "put error: %s\n", s.ToString().c_str());
			    exit(1);
		    }
		    value.clear();
		    thread->stats.FinishedSingleOp();
            continue;
	    }
    }
  }

  void ReadSequential(ThreadState* thread) {
    rocksdb::Iterator* iter = db_->NewIterator(rocksdb::ReadOptions());
    int i = 0;
    int64_t bytes = 0;
    for (iter->SeekToFirst(); i < reads_ && iter->Valid(); iter->Next()) {
      bytes += iter->key().size() + iter->value().size();
      thread->stats.FinishedSingleOp();
      ++i;
    }
    delete iter;
    thread->stats.AddBytes(bytes);
  }

  void ReadReverse(ThreadState* thread) {
    rocksdb::Iterator* iter = db_->NewIterator(rocksdb::ReadOptions());
    int i = 0;
    int64_t bytes = 0;
    for (iter->SeekToLast(); i < reads_ && iter->Valid(); iter->Prev()) {
      bytes += iter->key().size() + iter->value().size();
      thread->stats.FinishedSingleOp();
      ++i;
    }
    delete iter;
    thread->stats.AddBytes(bytes);
  }

  void ReadRandom(ThreadState* thread) {
    rocksdb::ReadOptions options;
    std::string value;
    int found = 0;
    for (int i = 0; i < reads_; i++) {
      const int k = thread->rand.Next() % FLAGS_num;
      if (db_->Get(options, allkeys_.at(k), &value).ok()) {
        found++;
      }
      thread->stats.FinishedSingleOp();
    }
    char msg[100];
    snprintf(msg, sizeof(msg), "(%d of %d found)", found, num_);
    thread->stats.AddMessage(msg);
  }

  void ReadMissing(ThreadState* thread) {
    rocksdb::ReadOptions options;
    std::string value;
    for (int i = 0; i < reads_; i++) {
      char key[100];
      const int k = thread->rand.Next() % FLAGS_num;
      snprintf(key, sizeof(key), "%016d.", k);
      db_->Get(options, key, &value);
      thread->stats.FinishedSingleOp();
    }
  }

  void ReadHot(ThreadState* thread) {
    rocksdb::ReadOptions options;
    std::string value;
    const int range = (FLAGS_num + 99) / 100;
    for (int i = 0; i < reads_; i++) {
      char key[100];
      const int k = thread->rand.Next() % range;
      snprintf(key, sizeof(key), "%016d", k);
      db_->Get(options, key, &value);
      thread->stats.FinishedSingleOp();
    }
  }

  void SeekRandom(ThreadState* thread) {
    rocksdb::ReadOptions options;
    std::string value;
    int found = 0;
    for (int i = 0; i < reads_; i++) {
      rocksdb::Iterator* iter = db_->NewIterator(options);
      char key[100];
      const int k = thread->rand.Next() % FLAGS_num;
      snprintf(key, sizeof(key), "%016d", k);
      iter->Seek(key);
      if (iter->Valid() && iter->key() == key) found++;
      delete iter;
      thread->stats.FinishedSingleOp();
    }
    char msg[100];
    snprintf(msg, sizeof(msg), "(%d of %d found)", found, num_);
    thread->stats.AddMessage(msg);
  }

  void DoDelete(ThreadState* thread, bool seq) {
    rocksdb::WriteBatch batch;
    rocksdb::Status s;
    for (int i = 0; i < num_; i += entries_per_batch_) {
      batch.Clear();
      for (int j = 0; j < entries_per_batch_; j++) {
        const int k = seq ? i+j : (thread->rand.Next() % FLAGS_num);
        char key[100];
        snprintf(key, sizeof(key), "%016d", k);
        batch.Delete(key);
        thread->stats.FinishedSingleOp();
      }
      s = db_->Write(write_options_, &batch);
      if (!s.ok()) {
        fprintf(stderr, "del error: %s\n", s.ToString().c_str());
        exit(1);
      }
    }
  }

  void DeleteSeq(ThreadState* thread) {
    DoDelete(thread, true);
  }

  void DeleteRandom(ThreadState* thread) {
    DoDelete(thread, false);
  }

  void ReadWriteDel(ThreadState* thread) {
	if (thread->tid % 3 == 0) { // read
      		ReadRandom(thread);
	} else if (thread->tid % 3 == 1) { // write
		int64_t num = 0; 
		while(true) {
			std::ifstream ifs(FLAGS_resource_data);  
			std::string str;  
			std::string key1;  
			std::string key2;  
			std::string key;  
			std::string value; 
			value.clear(); 
			rocksdb::Status s;	

			while(getline(ifs, str)) {
				if (str.find("product/productId:") == 0) {
                    key1 = str.substr(19);
				}
				if (str.find("review/userId:") == 0) {
                    key2 = str.substr(15);
				}
				if (str.find("review/profileName:") == 0) {
					value += str.substr(20);
					value += " ";
				}
				if (str.find("review/helpfulness:") == 0) {
					value += str.substr(20);
					value += " ";
				}
				if (str.find("review/score:") == 0) {
					value += str.substr(14);
					value += " ";
				}
				if (str.find("review/time:") == 0) {
					value += str.substr(13);
					value += " ";
				}
				if (str.find("review/summary:") == 0) {
					value += str.substr(16);
					value += " ";
				}
				if (str.find("review/text:") == 0) {
					value += str.substr(13);
				}

				if (str == "") {
                    key = key1 + " " + key2;
					s = db_->Put(write_options_, key, value);
					if (!s.ok()) {
						fprintf(stderr, "put error: %s\n", s.ToString().c_str());
						exit(1);
					}
                    num++;
					value.clear();
				}
				MutexLock l(&thread->shared->mu);
				if (thread->shared->num_done + 2*FLAGS_threads/3 >= thread->shared->num_initialized) {
					printf("extra write operations number %d\n", num);
					return;
				}
			}
		}
	} else {  // del
		int64_t num = 0;
    	rocksdb::Status s;
		while(true) {
			const int k = thread->rand.Next() % FLAGS_num;
			s = db_->Delete(write_options_, allkeys_.at(k));
			MutexLock l(&thread->shared->mu);
			num++;
			if (thread->shared->num_done + 2*FLAGS_threads/3 >= thread->shared->num_initialized) {
				printf("extra del operations number %d\n", num);
				break;
			}
		}
	} 
  }

  void ReadWhileWriting(ThreadState* thread) {
      if (thread->tid > 0) {
          ReadRandom(thread);
      } else {
          int64_t num = 0; 
          while(true) {
              std::ifstream ifs(FLAGS_resource_data);  
              std::string str;  
              std::string key1;  
              std::string key2;  
              std::string key;  
              std::string value; 
              value.clear(); 
              rocksdb::Status s;	

              while(getline(ifs, str)) {
                  if (str.find("product/productId:") == 0) {
                      key1 = str.substr(19);
                  }
                  if (str.find("review/userId:") == 0) {
                      key2 = str.substr(15);
                  }
                  if (str.find("review/profileName:") == 0) {
                      value += str.substr(20);
                      value += " ";
                  }
                  if (str.find("review/helpfulness:") == 0) {
                      value += str.substr(20);
                      value += " ";
                  }
                  if (str.find("review/score:") == 0) {
                      value += str.substr(14);
                      value += " ";
                  }
                  if (str.find("review/time:") == 0) {
                      value += str.substr(13);
                      value += " ";
                  }
                  if (str.find("review/summary:") == 0) {
                      value += str.substr(16);
                      value += " ";
                  }
                  if (str.find("review/text:") == 0) {
                      value += str.substr(13);
                  }

                  if (str == "") {
                      key = key1 + " " + key2;
                      s = db_->Put(write_options_, key, value);
                      if (!s.ok()) {
                          fprintf(stderr, "put error: %s\n", s.ToString().c_str());
                          exit(1);
                      }
                      num++;
                      value.clear();
                  }
                  MutexLock l(&thread->shared->mu);
                  if (thread->shared->num_done + 1 >= thread->shared->num_initialized) {
                      printf("extra write operations number %d\n", num);
                      return;
                  }
              }
          }
      }
  }

  void Compact(ThreadState* thread) {
    fprintf(stderr, "compact not supported\n");
    return;
/*
    db_->CompactRange(NULL, NULL);
*/
  }

  void PrintStats(const char* key) {
    std::string stats;
    if (!db_->GetProperty(key, &stats)) {
      stats = "(failed)";
    }
    fprintf(stdout, "\n%s\n", stats.c_str());
  }

  static void WriteToFile(void* arg, const char* buf, int n) {
    reinterpret_cast<WritableFile*>(arg)->Append(Slice(buf, n));
  }

  void HeapProfile() {
    fprintf(stderr, "heap profiling not supported\n");
    return;
/*
    char fname[100];
    snprintf(fname, sizeof(fname), "%s/heap-%04d", FLAGS_db, ++heap_counter_);
    std::unique_ptr<rocksdb::WritableFile> file;
    rocksdb::EnvOptions soptions;
    rocksdb::Status s = rocksdb::Env::Default()->NewWritableFile(fname, &file, soptions);
    if (!s.ok()) {
      fprintf(stderr, "%s\n", s.ToString().c_str());
      return;
    }
    bool ok = port::GetHeapProfile(WriteToFile, file);
    // delete file;
    if (!ok) {
      fprintf(stderr, "heap profiling not supported\n");
      rocksdb::Env::Default()->DeleteFile(fname);
    }
*/
  }
};

}  // namespace leveldb

int main(int argc, char** argv) {
  FLAGS_write_buffer_size = rocksdb::Options().write_buffer_size;
  FLAGS_open_files = rocksdb::Options().max_open_files;
  std::string default_db_path;

  for (int i = 1; i < argc; i++) {
    double d;
    // int n;
    long n;
    char junk;
    if (rocksdb::Slice(argv[i]).starts_with("--benchmarks=")) {
      FLAGS_benchmarks = argv[i] + strlen("--benchmarks=");
    } else if (sscanf(argv[i], "--compression_ratio=%lf%c", &d, &junk) == 1) {
      FLAGS_compression_ratio = d;
    } else if (sscanf(argv[i], "--histogram=%d%c", &n, &junk) == 1 &&
               (n == 0 || n == 1)) {
      FLAGS_histogram = n;
    } else if (sscanf(argv[i], "--use_existing_db=%d%c", &n, &junk) == 1 &&
               (n == 0 || n == 1)) {
      FLAGS_use_existing_db = n;
    } else if (sscanf(argv[i], "--num=%d%c", &n, &junk) == 1) {
      FLAGS_num = n;
    } else if (sscanf(argv[i], "--reads=%d%c", &n, &junk) == 1) {
      FLAGS_reads = n;
    } else if (sscanf(argv[i], "--threads=%d%c", &n, &junk) == 1) {
      FLAGS_threads = n;
    } else if (sscanf(argv[i], "--value_size=%d%c", &n, &junk) == 1) {
      FLAGS_value_size = n;
    } else if (sscanf(argv[i], "--write_buffer_size=%ld%c", &n, &junk) == 1) {
      FLAGS_write_buffer_size = n;
      std::cout << "FLAGS_write_buffer_size " << FLAGS_write_buffer_size << std::endl;
    } else if (sscanf(argv[i], "--cache_size=%ld%c", &n, &junk) == 1) {
      FLAGS_cache_size = n;
      std::cout << " cache size " << FLAGS_cache_size << std::endl;
    } else if (sscanf(argv[i], "--bloom_bits=%d%c", &n, &junk) == 1) {
      FLAGS_bloom_bits = n;
    } else if (sscanf(argv[i], "--open_files=%d%c", &n, &junk) == 1) {
      FLAGS_open_files = n;
    } else if (strncmp(argv[i], "--db=", 5) == 0) {
      FLAGS_db = argv[i] + 5;
    } else if (strncmp(argv[i], "--resource_data=", 16) == 0) {
      FLAGS_resource_data = argv[i] + 16;
    } else {
      fprintf(stderr, "Invalid flag '%s'\n", argv[i]);
      exit(1);
    }
  }

  // Choose a location for the test database if none given with --db=<path>
  if (FLAGS_db == NULL) {
      rocksdb::Env::Default()->GetTestDirectory(&default_db_path);
      default_db_path += "/dbbench";
      FLAGS_db = default_db_path.c_str();
  }

  shuff = (int *)malloc(FLAGS_num * sizeof(int));
  for (int i=0; i<FLAGS_num; i++)
    shuff[i] = i;
  leveldb::Benchmark benchmark;
  benchmark.Run();
  return 0;
}
