echo "####Now, running rocksdb benchmark"
rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
free -m
./db_bench_rocksdb --benchmarks=fillrandom,readrandom --value_size=64 --num=50000000 --reads=25000000 --write_buffer_size=67108864 --cache_size=201326592 --bloom_bits=5 --db=data
echo "####rocksdb benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
free -m
./db_bench_wiredtiger --benchmarks=fillrandom,readrandom --value_size=64 --num=50000000 --reads=25000000 --write_buffer_size=67108864 --cache_size=201326592 --bloom_bits=5 --db=data
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running narkdb benchmarks"
rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
free -m
cp dbmeta.json data/ 
./db_bench_nark --benchmarks=fillrandom,readrandom --value_size=64 --num=50000000 --reads=25000000 --sync_index=0 --db=data
echo "####nark benchmark finish"
free -m
