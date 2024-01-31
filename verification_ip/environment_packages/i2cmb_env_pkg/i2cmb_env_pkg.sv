//`timescale 1ns / 10ps
package i2cmb_env_pkg;
  import ncsu_pkg::*;
  import parameter_pkg::*;
  import i2c_pkg::*;
  import wb_pkg::*;
  
  `include "../../ncsu_pkg/src/wb_i2c_typedefs.svh"
  `include "src/ncsu_macros.svh"
  `include "src/i2cmb_env_configuration.svh"
  `include "src/i2cmb_scoreboard.svh"
  `include "src/i2cmb_predictor.svh"
  `include "src/i2cmb_coverage.svh"
  `include "src/i2cmb_environment.svh"
  `include "src/i2cmb_generator.svh"
  `include "src/i2cmb_reg_tests_generator.svh"
  `include "src/i2cmb_rand_tests_generator.svh"
  `include "src/i2cmb_test.svh"
endpackage