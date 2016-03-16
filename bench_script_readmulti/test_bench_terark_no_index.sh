#record_num=120000000
#read_num=60000000
record_num=800000
read_num=400000
dirname=/mnt/datamemory
#dirname=/experiment/terarkdb
value=128

rm -rf $dirname/*

export TMPDIR=$dirname
echo $TMPDIR

cp ../terarkschema/dbmeta_bench_no_index.json $dirname/dbmeta.json 

echo "####Now, running terark benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_bench_terark_no_index --benchmarks=fillrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname
free -m
date
echo "####terark benchmark finish"
du -s -b $dirname

echo "####Now, running terark benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_bench_terark_no_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname
free -m
date
echo "####terark benchmark finish"
du -s -b $dirname

echo "####Now, running terark benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_bench_terark_no_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --threads=8 --db=$dirname
free -m
date
echo "####terark benchmark finish"
du -s -b $dirname

#echo "####Now, running terark benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export NarkDb_WrSegCacheSizeMB=64
#../db_bench_terark_no_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --threads=16 --db=$dirname
#free -m
#date
#echo "####terark benchmark finish"
#du -s -b $dirname
#
#echo "####Now, running terark benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export NarkDb_WrSegCacheSizeMB=64
#../db_bench_terark_no_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --threads=24 --db=$dirname
#free -m
#date
#echo "####terark benchmark finish"
#du -s -b $dirname
#
#dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
#for i in $dstatpid
#do
#        kill -9 $i
#done
