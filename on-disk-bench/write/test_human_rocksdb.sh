nohup dstat -tcm --output /home/panfengfeng/trace_log/in-memory/humangenome/fillrandom_mulit_rocksdb_256 2 > nohup.out &

file=/data/publicdata/humangenome/xenoMrna.fa
record_num=17448961
dirname=/mnt/datamemory
writebuffer=268435456

rm -rf $dirname/*
echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_humangenome_rocksdb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --db=$dirname --resource_data=$file
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

rm -rf $dirname/*
echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_humangenome_rocksdb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --db=$dirname --resource_data=$file --threads=3
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

rm -rf $dirname/*
echo "####Now, running rocksdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_humangenome_rocksdb --benchmarks=fillrandom --num=$record_num --write_buffer_size=$writebuffer --db=$dirname --resource_data=$file --threads=6
free -m
date
echo "####rocksdb benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
