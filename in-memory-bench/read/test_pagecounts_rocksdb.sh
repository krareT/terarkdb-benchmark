nohup dstat -tcm --output /home/panfengfeng/trace_log/in-memory/pagecounts/readrandom_multi_rocksdb_256_3 2 > nohup.out &

file=/data/publicdata/pagecounts/pagecounts-2015-12-views-ge-5
record_num=65187562
read_num=65187562
dirname=/mnt/datamemory
writebuffer=268435456
cachesize=21729187

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

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=8 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=16 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
