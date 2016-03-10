file=/data/publicdata/wikiarticles/enwiki-latest.text
record_num=3977902
dirname=/experiment/rockswiki
writebuffer=67108864
cachesize=2147483648

rm -rf $dirname/*

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_rocksdb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname
