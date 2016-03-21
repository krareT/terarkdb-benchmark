# make exec file

case "$1" in
	rocksdb)
		echo "building rocksdb"
		case $2 in
			movie)
				make db_movies_rocksdb
				;;
			page)
				make db_pagecounts_rocksdb
				;;
			human)
				make db_humangenome_rocksdb
				;;
			wiki)
				make db_wikiarticles_rocksdb
				;;
			all)
				make db_movies_rocksdb
				make db_pagecounts_rocksdb
				make db_humangenome_rocksdb
				make db_wikiarticles_rocksdb
				;;
			*)
        			echo "Unknown platform!" >&2
        			exit 1
		esac
		;;
	wiredtiger)
		echo "building wiredtiger"
		case $2 in	
			movie)
				make db_movies_wiredtiger
				;;
			page)
				make db_pagecounts_wiredtiger
				;;
			human)
				make db_humangenome_wiredtiger
				;;
			wiki)
				make db_wikiarticles_wiredtiger
				;;
			all)
				make db_movies_wiredtiger
				make db_pagecounts_wiredtiger
				make db_humangenome_wiredtiger
				make db_wikiarticles_wiredtiger
		esac
		;;
	terarkdb)
		echo "building terark"
		case $2 in
			movie)
				make db_movies_terark_index
				;;
			page)
				make db_pagecounts_terark_index
				;;
			human)	
				make db_humangenome_terark_index
				;;
			wiki)
				make db_wikiarticles_terark_index
				;;
			all)
				make db_movies_terark_index
				make db_pagecounts_terark_index
				make db_humangenome_terark_index
				make db_wikiarticles_terark_index
		esac
		;;
	*)
        	echo "Unknown platform!" >&2
        	exit 1
esac
