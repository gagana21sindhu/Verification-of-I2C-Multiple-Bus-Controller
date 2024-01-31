class i2cmb_environment extends ncsu_component#(.T(i2c_transaction));

  i2cmb_env_configuration configuration;
  wb_agent         p0_agent;  //WB Agent
  i2c_agent        p1_agent;  //I2C Agent
  i2cmb_predictor         pred;
  i2cmb_scoreboard        scbd;
  i2cmb_coverage          coverage;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction : new

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration


  virtual function void build();
    //*** Building WB Agent *** //
    p0_agent = new("p0_agent",this);
    p0_agent.set_configuration(configuration.p0_agent_config);
    p0_agent.build();

    //*** Building I2C Agent *** //
    p1_agent = new("p1_agent",this);
    p1_agent.set_configuration(configuration.p1_agent_config);
    p1_agent.build();

    //*** Building Predictor , Scoreboard and Coverage *** //
    pred  = new("pred", this);
    pred.set_configuration(configuration);
    pred.build();
    scbd  = new("scbd", this);
    scbd.build();
    coverage = new("coverage", this);
    coverage.set_configuration(configuration);
    coverage.build();

    //*** Connecting the Predictor and Coverage to WB Agent ***//
    p0_agent.connect_subscriber(coverage);
    p0_agent.connect_subscriber(pred);

    pred.set_scoreboard(scbd); // Connecting Predictor to Scoreboard

    //*** Connecting the Scoreboard to I2C Agent ***//
    p1_agent.connect_subscriber(scbd);
  endfunction : build


  function ncsu_component#(wb_transaction) get_p0_agent();
    return p0_agent;
  endfunction : get_p0_agent

  function ncsu_component#(T) get_p1_agent();
    return p1_agent;
  endfunction : get_p1_agent

  //*** Calling run tasks of Agents which in turn will call the run tasks of Monitors and Driver(I2C) ***//
  virtual task run();
    p0_agent.run();  // WB Agent
    p1_agent.run();  // I2C Agent
  endtask : run

endclass : i2cmb_environment
