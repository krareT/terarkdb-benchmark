##terarkdb
#./test_movies_terark_index.sh > /home/panfengfeng/result-2/in-memory-result/movies/readwhilewriting_terark_index_256_4g_old
#
#./test_pagecounts_terark_index.sh > /home/panfengfeng/result-2/in-memory-result/pagecounts/readwhilewriting_terark_index_256_4g_old
#
#./test_human_terark_index.sh > /home/panfengfeng/result-2/in-memory-result/humangenome/readwhilewriting_terark_index_256_4g_old
#
#./test_wikiarticles_terark_index.sh > /home/panfengfeng/result-2/in-memory-result/wikiarticles/readwhilewriting_terark_index_256_4g_old

##wiredtiger
./test_movies_wiredtiger_over.sh > /home/panfengfeng/result-2/in-memory-result/movies/readwhilewriting_wiredtiger_no_lsm_256_over_2

./test_human_wiredtiger_over.sh > /home/panfengfeng/result-2/in-memory-result/humangenome/readwhilewriting_wiredtiger_no_lsm_256_over_2

./test_wikiarticles_wiredtiger_over.sh > /home/panfengfeng/result-2/in-memory-result/wikiarticles/readwhilewriting_wiredtiger_no_lsm_256_over_2

./test_pagecounts_wiredtiger_over.sh > /home/panfengfeng/result-2/in-memory-result/pagecounts/readwhilewriting_wiredtiger_no_lsm_256_over_2
