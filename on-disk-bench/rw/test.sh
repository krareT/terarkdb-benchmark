#movies
#./test_movies_rocksdb.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_rocksdb_256_95_512m_mem4g

#./test_movies_wiredtiger_over.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_wiredtiger_no_lsm_128m_over_95_mem2g

./test_movies_terark_index.sh >> /home/panfengfeng/result/on-disk/movies/readwhilewriting_terark_index_100_95_mem4g_mappopulate_256m_128m_details_fill_unsync_read_unsync_zipThreads_8_2

#./test_movies_leveldb.sh > /home/panfengfeng/result/on-disk/movies/readwhilewriting_leveldb_256_95_128m_mem2g
