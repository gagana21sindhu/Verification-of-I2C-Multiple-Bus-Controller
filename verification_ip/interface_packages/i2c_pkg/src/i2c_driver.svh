class i2c_driver extends ncsu_component#(.T(i2c_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction : new

  virtual i2c_if i2c_bus;             // Virtual i2c interface handle 
  i2c_configuration configuration;
  i2c_transaction i2c_trans;          // The i2c transaction to be passed by Generator 

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  //*************************************************************************************************************//
  // The Blocking put called by the Agent,
  // whose Blocking put was called by the Generator to pass the transaction //
  virtual task bl_put(T trans);
    i2c_trans = trans;
  endtask : bl_put


  //******** Driver run task, which executes provide_read_data (I2C_Generator initial block Proj1)********///
  // This provides the read data to the i2c interface from the generator //
  virtual task run();
    forever begin
      i2c_bus.wait_for_i2c_transfer(i2c_trans.i2c_op,i2c_trans.data);
      if(i2c_trans.i2c_op == 1) 
      begin
        i2c_bus.provide_read_data(i2c_trans.read_data,i2c_trans.transfer_complete);
      end
    end
  endtask : run 

endclass : i2c_driver
