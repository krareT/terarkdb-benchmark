file=/data/publicdata/wikiarticles/enwiki-latest.text
record_num=3977902
read_num=2000000
dirname=/mnt/datamemory

rm -rf $dirname/*

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_redis --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`
echo "####redis benchmark finish"
free -m

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_redis --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --resource_data=$file
free -m
date
echo "####redis benchmark finish"
du -s -b $dirname
#cachesize=`du -s -b -b $dirname | awk '{print $1}'`

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_redis --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --threads=8 --resource_data=$file
free -m
date
echo "####redis benchmark finish"
du -s -b $dirname
#

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_redis --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --threads=16 --resource_data=$file
free -m
date
echo "####redis benchmark finish"
du -s -b $dirname
#

echo "####Now, running redis benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../db_wikiarticles_redis --benchmarks=readrandom --num=$record_num --reads=$read_num --db=$dirname --threads=24 --resource_data=$file
free -m
date
echo "####redis benchmark finish"
du -s -b $dirname
#

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

