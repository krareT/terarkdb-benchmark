#movies

./test_movies_leveldb.sh > /home/panfengfeng/result/in-memory/movies/readrandom_multi_leveldb_256_3G

./test_movies_rocksdb.sh > /home/panfengfeng/result/in-memory/movies/readrandom_multi_rocksdb_256_3G

./test_movies_wiredtiger_over.sh > /home/panfengfeng/result/in-memory/movies/readrandom_multi_wiredtiger_no_lsm_3_over

./test_movies_terark_index.sh > /home/panfengfeng/result/in-memory/movies/readrandom_multi_terark_index_100_3G_new
