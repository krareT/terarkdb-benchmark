#!/bin/sh

# Run Wired Tiger Level DB benchmark.
# Assumes that a pre-built Wired Tiger library exists in ../wiredtiger.
# Assumes that the Wired Tiger build is shared, not static.
# but works if it is static.

BASHO_PATH="../basho.leveldb"
BDB_PATH="../db-5.3.21/build_unix"
MDB_PATH="../mdb/libraries/liblmdb"
SNAPPY_PATH="ext/compressors/snappy/.libs/"
WTDBG_PATH="../wiredtiger.dbg/build_posix"
WTOPT_PATH="../wiredtiger/build_posix"

test_compress()
{
	if [ ! -e "$WT_PATH/$SNAPPY_PATH/libwiredtiger_snappy.so" ]; then
		echo "Snappy compression not included in Wired Tiger."
		echo "Could not find $WT_PATH/$SNAPPY_PATH/libwiredtiger_snappy.so"
		echo `$WT_PATH/$SNAPPY_PATH/`
		exit 1
	fi
}

if test -f doc/bench/db_bench_wiredtiger.cc; then
	#
	# If the sources have a sleep in it, then we're profiling.  Use
	# the debug library so functions are not inlined.
	#
	grep -q sleep doc/bench/db_bench_wiredtiger.cc
	if test "$?" -eq 0; then
		WT_PATH=$WTDBG_PATH
	else
		WT_PATH=$WTOPT_PATH
	fi
fi

if [ `uname` == "Darwin" ]; then
	basholib_path="DYLD_LIBRARY_PATH=$BASHO_PATH:"
	bdblib_path="DYLD_LIBRARY_PATH=$BDB_PATH/.libs:"
	levellib_path="DYLD_LIBRARY_PATH=.:"
	mdblib_path="DYLD_LIBRARY_PATH=$MDB_PATH:"
	wtlib_path="DYLD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH"
else
	basholib_path="LD_LIBRARY_PATH=$BASHO_PATH:"
	bdblib_path="LD_LIBRARY_PATH=$BDB_PATH/.libs:"
	levellib_path="LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH"
	mdblib_path="LD_LIBRARY_PATH=$MDB_PATH:"
	wtlib_path="LD_LIBRARY_PATH=$WT_PATH/.libs:$WT_PATH/$SNAPPY_PATH:$LD_LIBRARY_PATH"
fi

#
# Workload to run, see -w below, is one of (default big):
# small - 4Mb cache (or 6Mb, smallest WT can use).
# big|large - 128Mb cache.
# val - 4Mb cache (or 6Mb for WT), 100000 byte values, limit to 10000 items.
# bigval - 512Mb cache, 100000 byte values, limit to 4000 items.
#
mb128=134217728
mb512=536870912
origbenchargs="--cache_size=$mb128"
mdb_benchargs=""
mb4="4194304"
mb4wt="6537216"

#
# The first set of args control the script or the program.  The remaining
# args are the database types to run.  It will run the configured controls
# on all the database types listed as the remaining args.
#
# Args are:
# -a args - Pass the given args along to the benchmark.
# -d dir - Use the given path for the benchmark.
# -F - (no arg) Turn off fast path directory checking.  Default off.
# -h - (no arg) Echo usage help statement and exit.
# -n # - Number of times to run the program for each database type. Default 3.
# -s suffix - Add the suffix string to the workload name.
# -S - Use the path to the SSD drive.
# -T - Use the path to the tmpfs.
# -t # - Number of threads to pass to program via --threads.  Default 1.
# NOTE: If a database type cannot support the number of threads given,
# it drops the number of threads to 1, but still runs the benchmark.
# -w <big|big512|bigval|small|val> - Workload to run.  Default big.
count=3
extraargs=""
fdir="./DATA"
op="big"
smallrun="no"
suffix=""
threadarg=1
ssddir="/mnt/fast/leveldbtest"
tmpfsdir="/tmpfs/leveldbtest"

usage="[-a bench_args][-d dir][-h][-n #][-s suffix][-S][-T][-t #][-w <big|big512|bigval|small|val>] db_source ..."
while getopts "a:d:hn:Ss:Tt:w:" Arg ;
	do case "$Arg" in
	a)
		extraargs+=$OPTARG" "
		;;
	d)
		datadir=$OPTARG
		;;
	h)
		echo $usage
		exit 0
		;;
	n)
		count=$OPTARG
		;;
	s)
		suffix=$OPTARG
		;;
	S)
		datadir=$ssddir
		;;
	T)
		datadir=$tmpfsdir
		;;
	t)
		threadarg=$OPTARG
		;;
	w)
		case "$OPTARG" in
		small)
			smallrun="yes"
			origbenchargs=""
			op="small";;
		big512)
			smallrun="no"
			origbenchargs="--cache_size=$mb512"
			op="big512";;
		big|large)
			smallrun="no"
			origbenchargs="--cache_size=$mb128"
			op="big";;
		bigval)
			smallrun="no"
			origbenchargs="--cache_size=$mb512 --value_size=100000 --num=4000"
			op="bigval";;
		val|smval)
			smallrun="yes"
			origbenchargs="--value_size=100000 --num=10000"
			op="val";;
		*)
			echo $usage
			exit 1;;
		esac
		;;
	*)
		echo $usage
		exit 1
		;;
	esac
done

shift `expr $OPTIND - 1`

# Now that we have the operation to run, do so on all remaining DB types.
while :
	benchargs=$origbenchargs
	do case "$1" in
	basho)
		fname=Basho
		libp=$basholib_path
		prog=./db_bench_basho
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	bashos|bashosymas)
		fname=Basho-symas
		libp=$basholib_path
		prog=./db_bench_bashosymas
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	bdb)
		fname=BDB
		libp=$bdblib_path
		prog=./db_bench_bdb
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	bdbs|bdbsymas)
		fname=BDB-symas
		libp=$bdblib_path
		prog=./db_bench_bdbsymas
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	ldb|leveldb|lvldb|lvl)
		fname=LevelDB
		libp=$levellib_path
		prog=./db_bench
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	ldbe|lvlext|lext|lvle)
		fname=LevelDBExt
		libp=$levellib_path
		prog=./db_bench_lvlext
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	ldbs|leveldbs|lvldbs|lvls)
		fname=LevelDB-symas
		libp=$levellib_path
		prog=./db_bench_leveldb
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4"
		}
		shift;;
	mdb)
		fname=MDB
		libp=$mdblib_path
		prog=./db_bench_mdb
		benchargs="$mdbbenchargs"
		shift;;
	mdbs|mdbsymas)
		fname=MDB-symas
		libp=$mdblib_path
		prog=./db_bench_mdbsymas
		benchargs="$mdbbenchargs"
		shift;;
	wt|wiredtiger|wtl|wtlsm)
		fname=WTlsm
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wtb|wiredtigerb)
		fname=WTbtree
		libp=$wtlib_path
		prog=./db_bench_wiredtiger
		benchargs="$origbenchargs --use_lsm=0"
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wte|wtext|wtextlsm)
		fname=WTlsmExt
		libp=$wtlib_path
		prog=./db_bench_wtext
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wtbe|wtbext)
		fname=WTbtreeExt
		libp=$wtlib_path
		prog=./db_bench_wtext
		benchargs="$origbenchargs --use_lsm=0"
		test "$smallrun" == "yes" && {
			benchargs="$benchargs --cache_size=$mb4wt"
		}
		test_compress
		shift;;
	wts|wtsymas)
		fname=WTlsm-symas
		libp=$wtlib_path
		prog=./db_bench_wtsymas
		test "$smallrun" == "yes" && {
			benchargs="$origbenchargs --cache_size=$mb4wt"
		}
		shift;;
	*)
		break;;
	esac
	
	# Set number of threads.  Some don't support it.
	case "$fname" in
	*LevelDB* | *WT*)
		threads=$threadarg
		benchargs="$benchargs --threads=$threads"
		;;
	*)
		if test "$threadarg" -gt "1"; then
			echo "WARNING: Thread argument ($threads) unsupported for $fname."
			echo "WARNING: Running with 1 thread only."
		fi
		threads=1
		;;
	esac
	fname=$fname$suffix

	# Check if there is a data directory defined.
	if test ! -z $datadir; then
		if test -e $datadir; then
			benchargs="$benchargs --db=$datadir"
		else
			echo "Data directory $datadir does not exist."
			exit 1
		fi
	fi
	# Add on any args the user specified.
	benchargs="$benchargs $extraargs"

	# If we have a command to execute do so.
	if test -e $prog; then
		i=0
		while test "$i" != "$count" ; do
			name=$fdir/$op.$$.$i.$fname.$threads
			echo "Benchmark output in $name"
			echo "env $libp $prog $benchargs"
			time env "$libp" $prog $benchargs > $name
			i=`expr $i + 1`
		done
	else
		echo "Skipping, $prog is not built."
	fi
done
