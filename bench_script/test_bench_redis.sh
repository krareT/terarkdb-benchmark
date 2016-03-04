record_num=80000000
read_num=40000000
#dirname=/data_memory/rocksdb
dirname=/mnt/datamemory
value=128

rm -rf $dirname/*

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_bench_redis --benchmarks=fillrandom --value_size=$value --num=$record_num --reads=$read_num --db=$dirname
free -m
date
echo "####wiredtiger redis finish"
du -s -b $dirname


echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_bench_redis --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --db=$dirname
free -m
date
echo "####redis benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
