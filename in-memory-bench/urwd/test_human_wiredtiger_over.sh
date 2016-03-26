nohup dstat -tcm --output /home/panfengfeng/trace_log/in-memory/humangenome/readwritedel_wiredtiger_no_lsm_3_over 2 > nohup.out &

file=/data/publicdata/humangenome/xenoMrna.fa
record_num=17448961
read_num=17448961
cachesize=4323254915
dirname=/mnt/datamemory

rm -rf $dirname/*
echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_humangenome_wiredtiger_overwrite --benchmarks=fillrandom --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --resource_data=$file
free -m
date
du -s -b $dirname
echo "####wiredtiger benchmark finish"

echo "####Now, running wiredtiger benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
../../db_humangenome_wiredtiger_overwrite --benchmarks=readwritedel --num=$record_num --reads=$read_num --db=$dirname --use_lsm=0 --cache_size=$cachesize --use_existing_db=1 --threads=12 --resource_data=$file
free -m
date
echo "####wiredtiger benchmark finish"
du -s -b $dirname

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done
#
