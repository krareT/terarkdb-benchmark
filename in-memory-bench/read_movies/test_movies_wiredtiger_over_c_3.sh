nohup dstat -tcm --output /home/panfengfeng/trace_log_2/movies/wiredtiger_c_3_2 2 > nohup.out &

file=/data/publicdata/movies/movies.txt
record_num=7911684
read_num=4000000
#cachesize=3221225472
cachesize=1610612736
dirname=/mnt/datamemory

rm -rf $dirname/*

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite_c_3 --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --resource_data=$file
free -m
date
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`
echo "####wiredtiger benchmark finish"
free -m

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite_c_3 --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --resource_data=$file
free -m
date
echo "####wiredtiger benchmark finish"
du -s -b $dirname

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite_c_3 --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --threads=8 --resource_data=$file
free -m
date
echo "####wiredtiger benchmark finish"
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_movies_wiredtiger_overwrite_c_3 --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --threads=16 --resource_data=$file
free -m
date
echo "####wiredtiger benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

