nohup dstat -tcmd -D sdc --output /home/panfengfeng/trace_log/on-disk/movies/fillrandom_mulit_leveldb_256_mem2g 2 > nohup.out &

file=/datainssd/publicdata/movies/movies.txt
record_num=7911684
dirname=/experiment
writebuffer=268435456

rm -rf $dirname/*
echo "####Now, running leveldb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_leveldb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --db=$dirname --resource_data=$file
free -m
date
echo "####leveldb benchmark finish"
du -s -b $dirname

rm -rf $dirname/*
echo "####Now, running leveldb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_leveldb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --db=$dirname --resource_data=$file --threads=3
free -m
date
echo "####leveldb benchmark finish"
du -s -b $dirname

rm -rf $dirname/*
echo "####Now, running leveldb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_leveldb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --db=$dirname --resource_data=$file --threads=6
free -m
date
echo "####leveldb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
