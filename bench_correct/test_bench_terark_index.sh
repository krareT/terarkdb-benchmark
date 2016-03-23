record_num=10000
read_num=10000
dirname=/mnt/datamemory
#dirname=/experiment
value=512

rm -rf $dirname/*

export TMPDIR=$dirname
echo $TMPDIR

cp ../terarkschema/dbmeta_bench_index.json $dirname/dbmeta.json 

echo "####Now, running terark benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=64
../db_bench_terark_index --benchmarks=fillrandom --value_size=$value --num=$record_num --reads=$read_num --db=$dirname --threads=1
free -m
date
echo "####terark benchmark finish"
du -s -b $dirname

echo "####Now, running terark benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDb_WrSegCacheSizeMB=64
../db_bench_terark_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --threads=1 --db=$dirname
free -m
date
echo "####terark benchmark finish"
du -s -b $dirname
#
##echo "####Now, running terark benchmark"
##echo 3 > /proc/sys/vm/drop_caches
##free -m
##date
##export TerarkDb_WrSegCacheSizeMB=64
##../db_bench_terark_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --threads=2 --db=$dirname
##free -m
##date
##echo "####terark benchmark finish"
##du -s -b $dirname
##
##echo "####Now, running terark benchmark"
##echo 3 > /proc/sys/vm/drop_caches
##free -m
##date
##export TerarkDb_WrSegCacheSizeMB=64
##../db_bench_terark_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --threads=16 --db=$dirname
##free -m
##date
##echo "####terark benchmark finish"
##du -s -b $dirname
##
##echo "####Now, running terark benchmark"
##echo 3 > /proc/sys/vm/drop_caches
##free -m
##date
##export TerarkDb_WrSegCacheSizeMB=64
##../db_bench_terark_index --benchmarks=readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --threads=24 --db=$dirname
##free -m
##date
##echo "####terark benchmark finish"
##du -s -b $dirname
##
##
##
##dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
##for i in $dstatpid
##do
##        kill -9 $i
##done
