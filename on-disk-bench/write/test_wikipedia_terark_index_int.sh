#nohup dstat -tcm --output terarkdb_wiredtiger_test_500M_3 2 > nohup.out &

file=/data/publicdata/wikipedia/datahandle/testwikipedia
record_num=45
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

#rm -rf $dirname/*
#export TMPDIR=$dirname
#echo $TMPDIR
#cp ../../terarkschema/dbmeta_movies_index.json $dirname/dbmeta.json
#echo "####Now, running terarkdb benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export TerarkDB_WrSegCacheSizeMB=100
#../../db_movies_terark_index --benchmarks=fillrandom --num=$record_num --sync_index=1 --db=$dirname --resource_data=$file --threads=3
#free -m
#date
#du -s -b $dirname
#echo "####terarkdb benchmark finish"

#rm -rf $dirname/*
#export TMPDIR=$dirname
#echo $TMPDIR
#cp ../../terarkschema/dbmeta_movies_index.json $dirname/dbmeta.json
#echo "####Now, running terarkdb benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#export TerarkDB_WrSegCacheSizeMB=100
#../../db_movies_terark_index --benchmarks=fillrandom --num=$record_num --sync_index=1 --db=$dirname --resource_data=$file --threads=6
#free -m
#date
#du -s -b $dirname
#echo "####terarkdb benchmark finish"
#
#dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
#for i in $dstatpid
#do
#        kill -9 $i
#done

