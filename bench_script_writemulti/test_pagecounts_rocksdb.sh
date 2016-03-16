nohup dstat -tcm --output /home/panfengfeng/trace_log_2/in-memory/pagecounts/fillrandom_mulit_rocksdb_256_256 2 > nohup.out &

file=/data/publicdata/pagecounts/pagecounts-2015-12-views-ge-5
record_num=65187562
read_num=32000000
dirname=/mnt/datamemory
#writebuffer=67108864
writebuffer=268435456
#cachesize=2147483648
cachesize=268435456

rm -rf $dirname/*
echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_rocksdb --benchmarks=fillrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

rm -rf $dirname/*
echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_rocksdb --benchmarks=fillrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --resource_data=$file --threads=6
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

rm -rf $dirname/*
echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_rocksdb --benchmarks=fillrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --resource_data=$file --threads=12
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
