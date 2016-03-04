file=/data/publicdata/movies/movies.txt
record_num=7911684
read_num=4000000
dirname=/mnt/datamemory

rm -rf $dirname/*

export TMPDIR=$dirname
echo $TMPDIR

cp ../narkschema/dbmeta_movies_no_index.json $dirname/dbmeta.json

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_nark --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname

#cachesize=`du -s -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_movies_nark --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
echo "####narkdb benchmark finish"
du -s -b $dirname
#cachesize=`du -s -b $dirname | awk '{print $1}'`

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

