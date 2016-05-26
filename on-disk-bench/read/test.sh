#movies
#./test_movies_wiredtiger_over.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_wiredtiger_no_lsm_256m_over_thread_8_mem4g

#./test_movies_rocksdb.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_rocksdb_256m_256m_thread_8_mem4g

#./test_movies_rocksdb_snappy_orign.sh > result_snappy_orign_256m_512m_mem8g_block4k
#./test_movies_rocksdb_zstd_orign.sh > result_zstd_orign_256m_512m_mem8g_block4k

#./test_movies_rocksdb_snappy_700.sh > result_snappy_700_256m_512m_mem8g_block4k
#./test_movies_rocksdb_zstd_700.sh > result_zstd_700_256m_512m_mem8g_block4k


#./test_movies_terark_index.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_terark_index_100_mem64g_mappopulate_16g_1g_fill_sync_read_sync_thread_8


#./test_movies_rocksdb_snappy_orign_8k.sh > result_snappy_orign_256m_512m_mem8g_block8k
#./test_movies_rocksdb_snappy_orign_16k.sh > result_snappy_orign_256m_512m_mem8g_block16k
#./test_movies_rocksdb_snappy_orign_32k.sh > result_snappy_orign_256m_512m_mem8g_block32k

#./test_movies_rocksdb_zstd_orign_8k.sh > result_zstd_orign_256m_512m_mem8g_block8k
#./test_movies_rocksdb_zstd_orign_16k.sh > result_zstd_orign_256m_512m_mem8g_block16k
#./test_movies_rocksdb_zstd_orign_32k.sh > result_zstd_orign_256m_512m_mem8g_block32k

#./test_movies_rocksdb_zstd_temp.sh > result_zstd_2_256m_512m_mem8g_block4k

./test_movies_rocksdb_snappy_orign_4k_compactrange.sh > result_snappy_orign_256m_512m_mem8g_block4k_compactrange
./test_movies_rocksdb_zstd_orign_4k_compactrange.sh > result_zstd_orign_256m_512m_mem8g_block4k_compactrange
