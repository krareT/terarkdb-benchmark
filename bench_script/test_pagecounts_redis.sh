#file=/data/publicdata/movies/movies.txt
file=test_file_pagecounts
#record_num=7911684
record_num=999967
#read_num=4000000
read_num=999967
dirname=/mnt/datamemory

rm -rf $dirname/*

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_redis --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`
echo "####redis benchmark finish"
free -m

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_redis --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --resource_data=$file
free -m
date
echo "####redis benchmark finish"
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

