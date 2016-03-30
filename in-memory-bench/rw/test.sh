#movies
./test_movies_rocksdb.sh > /home/panfengfeng/result/in-memory/movies/readwhilewriting_rocksdb_256_2

./test_movies_terark_index.sh > /home/panfengfeng/result/in-memory/movies/readwhilewriting_terark_index_256_2

./test_movies_wiredtiger_over.sh > /home/panfengfeng/result/in-memory/movies/readwhilewriting_wiredtiger_no_lsm_3_over_2

#./test_movies_terark_index_old.sh > /home/panfengfeng/result/in-memory/movies/readwhilewriting_terark_index_256_old
