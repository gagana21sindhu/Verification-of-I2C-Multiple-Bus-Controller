class i2c_agent extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration configuration;
  i2c_driver        driver;
  i2c_monitor       monitor;
  i2c_coverage      coverage;
  ncsu_component #(T) subscribers[$];
  virtual i2c_if    i2c_bus;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    //calling ncsu_config_db to fetch the virtual interface handle and assign to i2c_bus
    if ( !(ncsu_config_db#(virtual i2c_if)::get(get_full_name(), this.i2c_bus))) begin;
      $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      $finish;
    end
  endfunction : new

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  virtual function void build();
    //*** driver built and virtual interface handle passed to it 
    //so that it can access the DUT to perform the transactions initiated by the generator ***///
    driver = new("driver",this);
    driver.set_configuration(configuration);
    driver.build();
    driver.i2c_bus = this.i2c_bus;
    
    coverage = new("coverage",this);
    coverage.set_configuration(configuration);
    coverage.build();
    connect_subscriber(coverage);
  
    //*** monitor built and virtual interface handle passed to it 
    // to monitor the transactions on the I2C side *** //
    monitor = new("monitor",this);
    monitor.set_configuration(configuration);
    monitor.set_agent(this); // agent set for broadcasting 
    monitor.build();
    monitor.i2c_bus = this.i2c_bus;
  endfunction : build


  //*** The non_blocking put called by monitor to broadcast the monitored transaction ***//
  virtual function void nb_put(T trans);
    foreach(subscribers[i]) begin
      subscribers[i].nb_put(trans); // Every connected subscriber is passed with the monitored transaction 
    end
  endfunction : nb_put


  //*** The Blocking put of Agent called by the Generator to pass the transaction *** //
  virtual task bl_put(T trans);
    driver.bl_put(trans);
  endtask

  //*** Function called by the subscribers who wish to connect with the agent ***//
  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction


  //*** Agent run task to call the Forever run tasks of 
  //    Monitor and Driver of I2C and continue with parent thread ***// 
  virtual task run();
    fork 
        monitor.run();
        driver.run(); 
    join_none
  endtask

endclass : i2c_agent


