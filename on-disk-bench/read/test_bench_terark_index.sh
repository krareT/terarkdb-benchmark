record_num=262144
value_size=1024
read_num=10000
dirname=/data/terarkdata

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../../terarkschema/dbmeta_bench_index.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=100
../../db_bench_terark_index --benchmarks=fillrandom --value_size=$value_size --num=$record_num --sync_index=1 --db=$dirname
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=100
../../db_bench_terark_index --benchmarks=readrandom --value_size=$value_size --num=$record_num --reads=$read_num --sync_index=1 --db=$dirname
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname
