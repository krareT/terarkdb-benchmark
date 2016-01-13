value=128
record_num=50000000
read_num=25000000

echo "####Now, running narkdb benchmark"
#rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
dirname=data/nark_datadir_$(date +%s)
mkdir $dirname
cp dbmeta.json $dirname
free -m
export NarkDb_WrSegCacheSizeMB=67108864 
./db_bench_nark --benchmarks=fillrandom,readrandom --value_size=$value --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname
total_size=`du -s -b data | awk '{print $1}'`
echo $total_size
echo "####narkdb benchmark finish"
free -m

echo "####Now, running rocksdb benchmark"
#rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
dirname=data/rocksdb_datadir_$(date +%s)
mkdir $dirname
free -m
./db_bench_rocksdb --benchmarks=fillrandom,readrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=67108864 --cache_size=$total_size --bloom_bits=5 --db=$dirname
du -s -b data
echo "####rocksdb benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
#rm -rf data/*
echo 3 > /proc/sys/vm/drop_caches
dirname=data/wiredtiger_datadir_$(date +%s)
mkdir $dirname
free -m
./db_bench_wiredtiger --benchmarks=fillrandom,readrandom --value_size=$value --num=$record_num --reads=$read_num --write_buffer_size=67108864 --cache_size=$total_size --bloom_bits=5 --db=$dirname
du -s -b data
echo "####wiredtiger benchmark finish"
free -m
