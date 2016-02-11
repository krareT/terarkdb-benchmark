record_num=500000
readnum=300000
dirname=data_memory
#dirname=data/test_bench

rm -rf $dirname/*

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta_bench.json $dirname/dbmeta.json
free -m
date
export NarkDb_WrSegCacheSizeMB=64
./db_bench_nark --benchmarks=fillrandom --value_size=128 --num=$record_num --reads=$readnum --sync_index=0 --db=$dirname
date
du -s -b $dirname
cachesize=`du -s -b $dirname | awk '{print $1}'`
echo "####narkdb benchmark finish"
free -m

echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
cp dbmeta_bench.json $dirname/dbmeta.json
free -m
date
./db_bench_nark --benchmarks=readwhilewriting --value_size=128 --num=$record_num --reads=$readnum --sync_index=0 --threads=1 --db=$dirname
#./db_bench_nark --benchmarks=readrandom --value_size=128 --num=$record_num --reads=$readnum --sync_index=0 --threads=2 --db=$dirname
date
echo "####narkdb benchmark finish"
free -m

#echo "####Now, running narkdb benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_nark --benchmarks=readwhilewriting --value_size=128 --num=$record_num --reads=$readnum --sync_index=0 --threads=4 --db=$dirname
#date
#echo "####narkdb benchmark finish"
#free -m
#
#echo "####Now, running narkdb benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_nark --benchmarks=readwhilewriting --value_size=128 --num=$record_num --reads=$readnum --sync_index=0 --threads=8 --db=$dirname
#date
#echo "####narkdb benchmark finish"
#free -m


#rm -rf $dirname/*
#cachesize=3221225472
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_wiredtiger --benchmarks=fillrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_wiredtiger --benchmarks=readrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname --use_existing_db=1 --threads=2
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_wiredtiger --benchmarks=readrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname --use_existing_db=1 --threads=4
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
#echo "####Now, running wiredtiger benchmark"
#echo 3 > /proc/sys/vm/drop_caches
#free -m
#date
#./db_bench_wiredtiger --benchmarks=readrandom --value_size=128 --write_buffer_size=67108864 --bloom_bits=5 --cache_size=$cachesize --num=$record_num --reads=$readnum --db=$dirname --use_existing_db=1 --threads=8
#date
#du -s -b $dirname
#echo "####wiredtiger benchmark finish"
#free -m
#
