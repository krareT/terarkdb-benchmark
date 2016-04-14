# make exec file

case "$1" in
	movie)
		echo "building movies"
		make db_movies_leveldb
	        make db_movies_rocksdb
		make db_movies_wiredtiger_overwrite
		make db_movies_terark_index
		;;
	human)
		echo "building human"
		make db_humangenome_leveldb
                make db_humangenome_rocksdb
                make db_humangenome_wiredtiger_overwrite
                make db_humangenome_terark_index
		;;
	wiki)
		echo "building terark"
		make db_wikiarticles_leveldb
                make db_wikiarticles_rocksdb
		make db_wikiarticles_wiredtiger_overwrite
		make db_wikiarticles_terark_index
		;;
	pagecount)
		echo "building terark"
		make db_pagecounts_leveldb
                make db_pagecounts_rocksdb
		make db_pagecounts_wiredtiger_overwrite
		make db_pagecounts_terark_index
		;;
	*)
        	echo "Unknown platform!" >&2
        	exit 1
esac
