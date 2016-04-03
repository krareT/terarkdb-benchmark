#nohup dstat -tcm --output /home/panfengfeng/trace_log/in-memory/movies/readrandom_multi_terark_index_256_nolock_log 2 > nohup.out &

file=/data/publicdata/movies/movies.txt
record_num=7911684
read_num=7911684
dirname=/mnt/datamemory

rm -rf $dirname/*
export TMPDIR=$dirname
export TerarkDB_CompressionThreadsNum=1
cp ../../terarkschema/dbmeta_movies_index.json $dirname/dbmeta.json
echo "####Now, running terarkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export TerarkDB_WrSegCacheSizeMB=256
../../db_movies_terark_index --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
echo "####terarkdb benchmark finish"

#echo "####Now, running terarkdb benchmark"
#export TMPDIR=$dirname
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export TerarkDB_WrSegCacheSizeMB=256
#../../db_movies_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
#free -m
#date
#echo "####terarkdb benchmark finish"
#du -s -b $dirname
#
#echo "####Now, running terarkdb benchmark"
#export TMPDIR=$dirname
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export TerarkDB_WrSegCacheSizeMB=256
#../../db_movies_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=8 --resource_data=$file
#free -m
#date
#echo "####terarkdb benchmark finish"
#du -s -b $dirname
#
#echo "####Now, running terarkdb benchmark"
#export TMPDIR=$dirname
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export TerarkDB_WrSegCacheSizeMB=256
#../../db_movies_terark_index --benchmarks=readrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --threads=16 --resource_data=$file
#free -m
#date
#echo "####terarkdb benchmark finish"
#du -s -b $dirname
#
#dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
#for i in $dstatpid
#do
#        kill -9 $i
#done
##
