record_num=50000000
readnum=30000000
dirname=data_memory
#dirname=data/test_bench

rm -rf $dirname/*

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_redis --benchmarks=fillrandom --num=$record_num --reads=$readnum --db=$dirname
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_redis --benchmarks=readwhilewriting --num=$record_num --reads=$readnum
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_redis --benchmarks=readwhilewriting --num=$record_num --reads=$readnum --threads=2 --db=$dirname
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_redis --benchmarks=readwhilewriting --num=$record_num --reads=$readnum --threads=4 --db=$dirname
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
./db_bench_redis --benchmarks=readwhilewriting --num=$record_num --reads=$readnum --threads=8 --db=$dirname
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m
