echo "####Now, running narkdb benchmark"
rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta.json data/
free -m
env NarkDb_WrSegCacheSizeMB=64 ./db_bench_nark --benchmarks=fillrandom,readrandom --value_size=64 --num=50000000 --reads=25000000 --sync_index=0 --db=data
total_size=`du -s -b data`
echo $total_size
echo "####rocksdb benchmark finish"
free -m

echo "####Now, running rocksdb benchmark"
rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
free -m
./db_bench_rocksdb --benchmarks=fillrandom,readrandom --value_size=64 --num=50000000 --reads=25000000 --write_buffer_size=67108864 --cache_size=$total_size --bloom_bits=5 --db=data
du -s -b data
echo "####rocksdb benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
free -m
./db_bench_wiredtiger --benchmarks=fillrandom,readrandom --value_size=64 --num=50000000 --reads=25000000 --write_buffer_size=67108864 --cache_size=$total_size --bloom_bits=5 --db=data
du -s -b data
echo "####wiredtiger benchmark finish"
free -m
