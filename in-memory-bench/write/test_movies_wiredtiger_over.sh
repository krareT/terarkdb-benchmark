nohup dstat -tcm --output /home/panfengfeng/trace_log/in-memory/movies/fillrandom_mulit_wiredtiger_no_lsm_over 2 > nohup.out &

file=/datainssd/publicdata/movies/movies.txt
record_num=7911684
dirname=/mnt/datamemory

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --db=$dirname --use_lsm=0 --resource_data=$file
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --db=$dirname --use_lsm=0 --resource_data=$file --threads=3
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --db=$dirname --use_lsm=0 --resource_data=$file --threads=6
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

