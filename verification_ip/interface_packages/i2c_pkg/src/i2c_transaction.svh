class i2c_transaction extends ncsu_transaction;
  `ncsu_register_object(i2c_transaction)


  //******* Declaring the variables used in I2C_generator initial block in Proj1 (top.sv) ************//
  // This is the transaction used by generator for I2C interface where it sends the data for provide_read_data //
  bit[I2C_ADDR_WIDTH-1:0] addr;
  i2c_op_t i2c_op;
  bit[I2C_DATA_WIDTH-1:0] data[];
  bit transfer_complete;
  bit[I2C_DATA_WIDTH-1:0] read_data[];


  rand bit [I2C_DATA_WIDTH-1:0] random_read_data;
  function new(string name=""); 
    super.new(name);
  endfunction : new

  //*************************************************************************************//
  //*** Function used by generator to initiate the read data 
  //   for provide_read_data task of i2c_if for a transaction ***//
  function void init_read_data(bit[I2C_DATA_WIDTH-1:0] read_data[]);
   this.read_data = read_data;
  endfunction : init_read_data

  virtual function string convert2string();
     return {super.convert2string(),$sformatf("Slave Address:0x%x Operation_mode:0x%x Data:0x%p", addr, i2c_op, data)};
  endfunction : convert2string

  function bit compare(i2c_transaction rhs);
    return ((this.addr  == rhs.addr ) && 
            (this.i2c_op == rhs.i2c_op) &&
            (this.data == rhs.data) );
  endfunction : compare

endclass : i2c_transaction
