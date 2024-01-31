class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration  configuration;
  virtual i2c_if i2c_bus;              // Virtual I2C interface handle

  T monitored_trans;                   // I2C transaction for monitoring 
  ncsu_component #(T) agent;           // I2C agent

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction : new

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction : set_agent
  
  virtual task run ();
      forever begin
        monitored_trans = new("monitored_trans"); // Creating a new transaction for a container to put the monitored data in
        i2c_bus.monitor(monitored_trans.addr, monitored_trans.i2c_op, monitored_trans.data);
        agent.nb_put(monitored_trans); // Broadcasting the monitored transaction to the subscribers of the agent
      end
  endtask : run

endclass : i2c_monitor
