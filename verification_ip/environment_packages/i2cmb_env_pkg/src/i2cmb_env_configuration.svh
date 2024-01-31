class i2cmb_env_configuration extends ncsu_configuration;

  wb_configuration  p0_agent_config;
  i2c_configuration p1_agent_config;

  covergroup env_configuration_cg;
  endgroup

  function void sample_coverage();
  	env_configuration_cg.sample();
  endfunction : sample_coverage

  function new(string name=""); 
    super.new(name);
    env_configuration_cg = new;
    p0_agent_config = new("p0_agent_config");
    p1_agent_config = new("p1_agent_config");
  endfunction : new

endclass : i2cmb_env_configuration
