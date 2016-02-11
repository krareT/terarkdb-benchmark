file=data/movies.txt
readnum=4000000
record_num=7911684
dirname=data/test_movies
rm -rf $dirname

mkdir $dirname

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta_movies_no_index.json $dirname/dbmeta.json
free -m
date
export NarkDb_WrSegCacheSizeMB=64
./db_movies_nark --benchmarks=fillrandom --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname --resource_data=$file
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
./db_movies_nark --benchmarks=readrandom --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname --resource_data=$file
date
du -s -b $dirname
#cachesize=`du -s -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m

rm -rf $dirname

#cachesize=2147483648
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_movies_wiredtiger --benchmarks=fillrandom --reads=$readnum --db=$dirname --use_lsm=0 --resource_data=$file
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_movies_wiredtiger --benchmarks=readrandom --num=$record_num --reads=$readnum --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --resource_data=$file
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
