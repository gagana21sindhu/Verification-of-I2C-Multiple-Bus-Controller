class wb_driver extends ncsu_component#(.T(wb_transaction));

  virtual wb_if wb_bus;            // Virtual WB interface handle
  wb_configuration configuration;
  wb_transaction wb_trans;         // WB transaction

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction : new

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  //*************************************************************************************************************//
  // The Blocking put called by the Agent,
  // whose Blocking put was called by the Generator to pass the transaction //
  virtual task bl_put(T trans);
    if(trans.wb_op == 1)
    begin
        wb_bus.master_write(trans.addr,trans.data);
    end
    else if(trans.wb_op == 0)
    begin
        wb_bus.master_read(trans.addr,trans.data);
    end
    else if(trans.wb_op == 2)
    begin
        interrupt_detect(trans);
    end
  endtask : bl_put

  //**************************************************************************************************//
  // Interrupt detect task to wait fot interrupt and clear by reading CMDR //
  virtual task interrupt_detect(T trans);
    wb_bus.wait_for_interrupt();
    wb_bus.master_read(trans.addr,trans.data);
  endtask : interrupt_detect

endclass : wb_driver
