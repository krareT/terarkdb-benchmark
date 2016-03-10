file=/data/publicdata/wikiarticles/enwiki-latest.text
record_num=3977902
dirname=/experiment/narkwiki

rm -rf $dirname/*

export TMPDIR=$dirname
echo $TMPDIR

cp ../narkschema/dbmeta_wikiarticles_no_index.json $dirname/dbmeta.json

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=64
../db_wikiarticles_nark --benchmarks=fillrandom --num=$record_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m
