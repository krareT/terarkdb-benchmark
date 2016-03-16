nohup dstat -tcm --output /home/panfengfeng/trace_log_2/in-memory/wikiarticles/fillrando_mulit_wiredtiger_no_lsm_256_over 2 > nohup.out &

file=/data/publicdata/wikiarticles/enwiki-latest.text
record_num=3977902
read_num=2000000
writebuffer=67108864
cachesize=268435456
dirname=/mnt/datamemory
#cachesize=67108864

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --resource_data=$file
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --resource_data=$file --threads=6
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --resource_data=$file --threads=12
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"
free -m

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

