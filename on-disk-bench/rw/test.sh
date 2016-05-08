#movies
./test_movies_rocksdb.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_rocksdb_256_99_128m_mem2g

./test_movies_wiredtiger_over.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_wiredtiger_no_lsm_128m_over_99_mem2g

./test_movies_terark_index.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_terark_index_100_99_mem2g_16g

./test_movies_leveldb.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_leveldb_256_99_128m_mem2g
