dstatpid=`ps aux | grep test.sh | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

dstatpid=`ps aux | grep test_ | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

dstatpid=`ps aux | grep db_ | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done

dstatpid=`ps aux | grep dstat | awk '{if($0 !~ "grep"){print $2}}'`
for i in $dstatpid
do
        kill -9 $i
done


