record_num=5000000
read_num=5000000
#dirname=/data_memory/wiredtiger
dirname=/mnt/datamemory
#dirname=/experiment/wiredtiger
writebuffer=67108864
cachesize=2147483648
value=512

#rm -rf $dirname/*
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
##../db_bench_wiredtiger --benchmarks=fillrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname
#../db_bench_wiredtiger --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$writebuffer
#free -m
#date
#echo "####wiredtiger benchmark finish"
#du -s -b $dirname
#
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
#../db_bench_wiredtiger --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1
../db_bench_wiredtiger --benchmarks=readwhilewriting --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$writebuffer --use_existing_db=1 --threads=8
free -m
date
echo "####wiredtiger benchmark finish"
du -s -b $dirname
