class i2cmb_coverage extends ncsu_component #(.T(wb_transaction));

  i2cmb_env_configuration	configuration;
  wb_transaction		coverage_transaction;

  covergroup coverage_cg;
  	option.per_instance = 1;
    option.name = get_full_name();
  endgroup : coverage_cg

  function void set_configuration(i2cmb_env_configuration cfg);
  	configuration = cfg;
  endfunction : set_configuration

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    coverage_cg = new;
  endfunction : new

  virtual function void nb_put(T trans);
    coverage_cg.sample();
  endfunction : nb_put

endclass : i2cmb_coverage