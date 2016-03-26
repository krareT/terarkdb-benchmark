nohup dstat -tcm --output /home/panfengfeng/trace_log/in-memory/pagecounts/fillrandom_mulit_terark_index_256 2 > nohup.out &

file=/data/publicdata/pagecounts/pagecounts-2015-12-views-ge-5
record_num=65187562
dirname=/mnt/datamemory

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../../terarkschema/dbmeta_pagecounts_index.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=256
../../db_pagecounts_terark_index --benchmarks=fillrandom --num=$record_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../../terarkschema/dbmeta_pagecounts_index.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=256
../../db_pagecounts_terark_index --benchmarks=fillrandom --num=$record_num --sync_index=0 --db=$dirname --resource_data=$file --threads=3
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../../terarkschema/dbmeta_pagecounts_index.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=256
../../db_pagecounts_terark_index --benchmarks=fillrandom --num=$record_num --sync_index=0 --db=$dirname --resource_data=$file --threads=6
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

