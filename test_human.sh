file=data/xenoMrna.fa
record_num=17448961
readnum=10000000
dirname=data/test_human
rm -rf $dirname
mkdir $dirname

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta_humangenome_no_index.json $dirname/dbmeta.json
free -m
date
#export NestLoudsTrie_nestLevel=3
export NarkDb_WrSegCacheSizeMB=64
./db_humangenome_nark --benchmarks=fillrandom --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname --resource_data=$file
date
du -s -b $dirname
cache_size=`du -s -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
./db_humangenome_nark --benchmarks=readrandom --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname --resource_data=$file
date
du -s -b $dirname
cache_size=`du -s -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m


#cachesize=2147483648
#
#rm -rf $dirname/*
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_humangenome_wiredtiger --benchmarks=fillrandom --reads=$readnum --db=$dirname --use_lsm=0 --resource_data=$file
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_humangenome_wiredtiger --benchmarks=readrandom --num=$record_num --reads=$readnum --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --resource_data=$file
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
