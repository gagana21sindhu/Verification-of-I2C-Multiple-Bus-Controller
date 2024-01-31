class wb_agent extends ncsu_component#(.T(wb_transaction));

  wb_configuration configuration;
  wb_driver        driver;            
  wb_monitor       monitor;
  wb_coverage      coverage;
  ncsu_component #(T) subscribers[$]; // Subscriber Queue
  virtual wb_if    wb_bus;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    //calling ncsu_config_db to fetch the virtual interface handle and assign to wb_bus
    if ( !(ncsu_config_db#(virtual wb_if)::get(get_full_name(), this.wb_bus))) begin;
      $display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      $finish;
    end
  endfunction : new

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  virtual function void build();
    //*** driver built and virtual interface handle passed to it 
    //so that it can access the DUT to perform the transactions initiated by the generator ***///
    driver = new("driver",this);
    driver.set_configuration(configuration);
    driver.build();
    driver.wb_bus = this.wb_bus;
    
    coverage = new("coverage",this);
    coverage.set_configuration(configuration);
    coverage.build();
    connect_subscriber(coverage);

    //*** monitor built and virtual interface handle passed to it 
    //    to monitor the transactions on the WB side *** //
    monitor = new("monitor",this);
    monitor.set_configuration(configuration);
    monitor.set_agent(this);
    monitor.build();
    monitor.wb_bus = this.wb_bus;
  endfunction : build


  //*** The non_blocking put called by monitor to broadcast the monitored transaction ***//
  virtual function void nb_put(T trans);
    foreach (subscribers[i]) begin
      subscribers[i].nb_put(trans); // Every connected subscriber is passed with the monitored transaction 
    end
  endfunction : nb_put


  //*** The Blocking put of Agent called by the Generator to pass the transaction *** //
  virtual task bl_put(T trans);
    driver.bl_put(trans);
  endtask : bl_put


  //*** Function called by the subscribers who wish to connect with the agent ***//
  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction : connect_subscriber


  //*** Agent run task to call the Forever run tasks of Monitor of WB and continue with parent thread ***//
  virtual task run();
    fork 
      monitor.run(); 
    join_none
  endtask : run

endclass : wb_agent


