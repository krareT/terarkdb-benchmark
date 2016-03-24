#nohup dstat -tcmd -D sdc --output /home/panfengfeng/trace_log_2/on-disk/movies/fillrandom_readrandom_mulit_rocksdb_1024_1024 2 > nohup.out &
nohup dstat -tcm --output /home/panfengfeng/temp 2 > nohup.out &

file=/data/publicdata/movies/movies.txt
record_num=7911684
read_num=4000000
dirname=/experiment
writebuffer=268435456
cachesize=268435456
#writebuffer=1073741824
#cachesize=1073741824

rm -rf $dirname/*

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_rocksdb --benchmarks=fillrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --resource_data=$file
#../../db_movies_rocksdb --benchmarks=fillrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --bloom_bits=5 --db=$dirname --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --resource_data=$file
#../../db_movies_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --bloom_bits=5 --db=$dirname --use_existing_db=1 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=8 --resource_data=$file
#../../db_movies_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=8 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=16 --resource_data=$file
#../../db_movies_rocksdb --benchmarks=readrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=16 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done