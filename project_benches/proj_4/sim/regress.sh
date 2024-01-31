make cli GEN_TYPE=i2cmb_reg_tests_generator
make cli GEN_TYPE=i2cmb_generator
make cli GEN_TYPE=i2cmb_rand_tests_generator TEST SEED=12345



make merge_coverage
make view_coverage





