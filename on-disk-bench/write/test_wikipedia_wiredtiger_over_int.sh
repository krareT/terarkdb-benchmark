file=/experiment/wikipedia/14filenorepeat
record_num=38508221
dirname=/experiment/wiredtiger

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_wikipedia_wiredtiger_overwrite_int --benchmarks=fillrandom --num=$record_num --db=$dirname --use_lsm=0 --resource_data=$file
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
