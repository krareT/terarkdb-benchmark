file=data/pagecounts-2015-12-views-ge-5
readnum=32000000
record_num=65187562
dirname=data/test_pagecounts
rm -rf $dirname
mkdir $dirname

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta_pagecounts_no_index.json $dirname/dbmeta.json
free -m
date
export NarkDb_WrSegCacheSizeMB=64
./db_pagecounts_nark --benchmarks=fillrandom --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname --resource_data=$file
date
du -s -b $dirname
cache_size=`du -s -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta_pagecounts_no_index.json $dirname/dbmeta.json
free -m
date
export NarkDb_WrSegCacheSizeMB=64
./db_pagecounts_nark --benchmarks=readrandom --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname --resource_data=$file
date
du -s -b $dirname
echo "####narkdb benchmark finish"
free -m

#cachesize=2147483648
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_pagecounts_wiredtiger --benchmarks=fillrandom --reads=$readnum --db=$dirname --use_lsm=0 --resource_data=$file
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_pagecounts_wiredtiger --benchmarks=readrandom --num=$record_num --reads=$readnum --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --resource_data=$file
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
