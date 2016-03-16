file=/data/publicdata/movies/movies.txt
record_num=7911684
read_num=4000000
#file=../test_file_movies
#record_num=12
#read_num=12
dirname=/mnt/datamemory

rm -rf $dirname/*

export TMPDIR=$dirname
echo $TMPDIR

cp ../terarkschema/dbmeta_movies_no_index.json $dirname/dbmeta.json

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_terark --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
#cachesize=`du -s -b $dirname | awk '{print $1}'`
echo "####terarkdb benchmark finish"
free -m

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_terark --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_terark --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=8 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_terark --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=16 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_terark --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=24 --resource_data=$file
free -m
date
echo "####terarkdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

