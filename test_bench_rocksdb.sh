record_num=80000000
read_num=40000000
#dirname=/data_memory/rocksdb
dirname=/mnt/datamemory
writebuffer=67108864
cachesize=2147483648
value=128

rm -rf $dirname/*

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
#./db_bench_rocksdb_new --benchmarks=fillrandom --num=$record_num --reads=$readnum --db=$dirname
date
./db_bench_rocksdb_new --benchmarks=fillrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
#./db_bench_rocksdb_new --benchmarks=readwhilewriting --num=$record_num --reads=$readnum --threads=1 --db=$dirname --use_existing_db=1
#./db_bench_rocksdb_new --benchmarks=readrandom --num=$record_num --reads=$readnum --threads=1 --db=$dirname --use_existing_db=1
free -m
date
./db_bench_rocksdb_new --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
