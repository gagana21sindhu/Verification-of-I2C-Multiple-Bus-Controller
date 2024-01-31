class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration configuration;
  bit [I2C_ADDR_WIDTH-2:0] i2c_addr;
  i2c_op_t i2c_op;
 
  

  covergroup i2c_transaction_cg with function sample(bit [I2C_DATA_WIDTH-1:0] i2c_data);
    option.per_instance = 1;
    option.name = get_full_name();
    i2c_addr : coverpoint i2c_addr;
    i2c_op : coverpoint i2c_op;
    i2c_data : coverpoint i2c_data;
    i2c_data_x_op : cross i2c_data, i2c_op;
  endgroup : i2c_transaction_cg
  

 
  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    i2c_transaction_cg = new;
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    //$display("i2c_coverage::nb_put() %s called",get_full_name());
    i2c_addr = trans.addr;
    i2c_op = i2c_op_t'(trans.i2c_op);
    foreach(trans.data[i]) begin
     i2c_transaction_cg.sample(trans.data[i]);
    end
  endfunction

endclass : i2c_coverage
