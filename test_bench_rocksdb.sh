record_num=50000000
readnum=30000000
dirname=data_memory
#dirname=data/test_bench

rm -rf $dirname/*

cachesize=3221225472

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_rocksdb_new --benchmarks=fillrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_rocksdb_new --benchmarks=readrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname --use_existing_db=1 --threads=2
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_rocksdb_new --benchmarks=readrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname --use_existing_db=1 --threads=4
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_rocksdb_new --benchmarks=readrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname --use_existing_db=1 --threads=8
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

