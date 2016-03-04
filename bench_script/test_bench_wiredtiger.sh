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
date
./db_bench_wiredtiger --benchmarks=fillrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname
#./db_bench_wiredtiger --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_wiredtiger --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1
#./db_bench_wiredtiger --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
