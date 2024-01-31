class i2cmb_test extends ncsu_component#(.T(wb_transaction));

  i2cmb_env_configuration  cfg;
  i2cmb_environment        env;
  i2cmb_generator          gen;
  string gen_type;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    if(!$value$plusargs("GEN_TYPE=%s", gen_type)) begin
      $display("FATAL: +GEN_TYPE plusarg not found on command line");
      $fatal;
    end
    $display("GEN_TYPE = %s", gen_type);
    cfg = new("cfg");
    cfg.sample_coverage();
    env = new("env",this);
    env.set_configuration(cfg);
    env.build();
    //gen = new("gen",this);
    $cast(gen,ncsu_object_factory::create(gen_type));
    gen.set_agent0(env.get_p0_agent());
    gen.set_agent1(env.get_p1_agent());
  endfunction : new

  //*** Test run task to call the env and gen run ***//
  virtual task run();
    env.run();
    gen.run();  
  endtask

endclass : i2cmb_test
