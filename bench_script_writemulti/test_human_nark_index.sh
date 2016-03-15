nohup dstat -tcm --output /home/panfengfeng/trace_log_2/in-memory/humangenome/fillrandom_mulit_nark_index_256_4g 2 > nohup.out &

file=/data/publicdata/humangenome/xenoMrna.fa
record_num=17448961
read_num=10000000
dirname=/mnt/datamemory

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../narkschema/dbmeta_humangenome_index.json $dirname/dbmeta.json
echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=256
../db_humangenome_nark_index --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file
free -m
date
du -s -b $dirname
echo "####narkdb benchmark finish"
free -m

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../narkschema/dbmeta_humangenome_index.json $dirname/dbmeta.json
echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=256
../db_humangenome_nark_index --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file --threads=8
free -m
date
du -s -b $dirname
echo "####narkdb benchmark finish"
free -m

rm -rf $dirname/*
export TMPDIR=$dirname
echo $TMPDIR
cp ../narkschema/dbmeta_humangenome_index.json $dirname/dbmeta.json
echo "####Now, running narkdb benchmark"
echo 3 > /proc/sys/vm/drop_caches
free -m
date
export NarkDb_WrSegCacheSizeMB=256
../db_humangenome_nark_index --benchmarks=fillrandom --num=$record_num --reads=$read_num --sync_index=0 --db=$dirname --resource_data=$file --threads=16
free -m
date
du -s -b $dirname
echo "####narkdb benchmark finish"
free -m



dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

