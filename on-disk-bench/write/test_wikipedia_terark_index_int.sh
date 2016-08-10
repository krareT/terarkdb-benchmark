file=/experiment/wikipedia/14filenorepeat
record_num=38508221
dirname=/experiment/terarkdb

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../../terarkschema/dbmeta_wikipedia_index_int.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=500
../../db_wikipedia_terark_index_int --benchmarks=fillrandom --num=$record_num --sync_index=1 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"
