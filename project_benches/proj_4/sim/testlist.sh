
#  Register tests generator (all the tasks for the register tests are run through this generator)
make cli GEN_TYPE=i2cmb_reg_tests_generator

# # # Compulsory Tests # # #
# Directed test with continous write , read and alternate read write
make cli GEN_TYPE=i2cmb_generator

# Random tests with continuous write, read and alternate read write with random data values and random slave addresses 
make cli GEN_TYPE=i2cmb_rand_tests_generator TEST SEED=12345


# To merge and view the coverage 
make merge_coverage
make view_coverage
