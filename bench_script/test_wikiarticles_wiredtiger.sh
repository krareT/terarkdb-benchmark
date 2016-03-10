file=/data/publicdata/wikiarticles/enwiki-latest.text
record_num=3977902
dirname=/experiment/narkwiki
writebuffer=67108864
cachesize=67108864
dirname=/experiment/wiredwiki

rm -rf $dirname/*

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_pagecounts_wiredtiger --benchmarks=fillrandom --num=$record_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --resource_data=$file
free -m
date
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`
echo "####wiredtiger benchmark finish"
free -m
