nohup dstat -tcmd -D sdc --output /home/panfengfeng/trace_log_2/on-disk/pagecounts/fillrandom_readrandom_mulit_terark_index_1024 2 > nohup.out &

file=/data/publicdata/pagecounts/pagecounts-2015-12-views-ge-5
record_num=65187562
read_num=32000000
dirname=/experiment

rm -rf $dirname/*

export TMPDIR=$dirname
echo $TMPDIR

cp ../terarkschema/dbmeta_pagecounts_index.json $dirname/dbmeta.json

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=1024
../db_pagecounts_terark_index --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname

echo "####terarkdb benchmark finish"
free -m

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=1024
../db_pagecounts_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=1024
../db_pagecounts_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=8 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname
#

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=1024
../db_pagecounts_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=16 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

