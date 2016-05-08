nohup dstat -tcmd -D sdc --output /home/panfengfeng/trace_log/on-disk/movies/readrandom_multi_terark_index_100_mem2g_16g_1g 2 > nohup.out &

file=/datainssd/publicdata/movies/movies.txt
record_num=7911684
read_num=4000000
dirname=/experiment

rm -rf $dirname/*
export TMPDIR=$dirname
cp ../../terarkschema/dbmeta_movies_index.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=100
../../db_movies_terark_index --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=1 --db=$dirname --resource_data=$file
#exit
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"

echo "####Now, running terarkdb benchmark"
export TMPDIR=$dirname
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=100
../../db_movies_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=1 --db=$dirname --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

echo "####Now, running terarkdb benchmark"
export TMPDIR=$dirname
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=100
../../db_movies_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=1 --db=$dirname --threads=8 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

echo "####Now, running terarkdb benchmark"
export TMPDIR=$dirname
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=100
../../db_movies_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=1 --db=$dirname --threads=16 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

