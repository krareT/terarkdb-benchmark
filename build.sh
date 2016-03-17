# make exec file

case "$1" in
	rocksdb)
		echo "building rocksdb"
		make db_movies_rocksdb
		make db_pagecounts_rocksdb
		make db_humangenome_rocksdb
		make db_wikiarticles_rocksdb
		;;
	wiredtiger)
		echo "building wiredtiger"
		make db_movies_wiredtiger_overwrite
		make db_pagecounts_wiredtiger_overwrite
		make db_humangenome_wiredtiger_overwrite
		make db_wikiarticles_wiredtiger_overwrite
		;;
	terarkdb)
		echo "building terark"
		make db_movies_terark_index
		make db_pagecounts_terark_index
		make db_humangenome_terark_index
		make db_wikiarticles_terark_index
		;;
	*)
        	echo "Unknown platform!" >&2
        	exit 1
esac
