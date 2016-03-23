nohup dstat -tcm --output /home/panfengfeng/trace_log_2/in-memory/movies/readwhilewriting_rocksdb_256_256 2 > nohup.out &

file=/data/publicdata/movies/movies.txt
#file=test_file_movies
record_num=7911684
#record_num=11
read_num=4000000
#read_num=11
dirname=/mnt/datamemory
#writebuffer=67108864
writebuffer=268435456
#cachesize=67108864
cachesize=268435456
#cachesize=2147483648

rm -rf $dirname/*

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_movies_rocksdb --benchmarks=fillrandom --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_movies_rocksdb --benchmarks=readwhilewriting --num=$record_num --reads=$read_num --write_buffer_size=$writebuffer --cache_size=$cachesize --bloom_bits=5 --db=$dirname --use_existing_db=1 --threads=8 --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
