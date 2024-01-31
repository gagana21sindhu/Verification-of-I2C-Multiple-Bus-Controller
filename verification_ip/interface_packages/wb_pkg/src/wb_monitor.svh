class wb_monitor extends ncsu_component#(.T(wb_transaction));

  wb_configuration  configuration;
  virtual wb_if wb_bus;  	               // Virtual WB interface handle

  ncsu_component #(T) agent;	           // WB Agent
  T monitored_trans;		                 // WB transaction for monitoring

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction : new

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  function void set_agent(ncsu_component#(wb_transaction) agent);
    this.agent = agent;
  endfunction : set_agent
  
  virtual task run ();
      wb_bus.wait_for_reset();
      forever begin
        monitored_trans = new("monitored_trans"); // Creating a new transaction for a container to put the monitored data in
        wb_bus.master_monitor(monitored_trans.addr,monitored_trans.data,monitored_trans.we);
        agent.nb_put(monitored_trans); // Broadcasting to the subscribers
    end
  endtask : run

endclass : wb_monitor