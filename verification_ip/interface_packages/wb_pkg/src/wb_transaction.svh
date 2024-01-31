class wb_transaction extends ncsu_transaction;
  `ncsu_register_object(wb_transaction)

  //*** Declaring the variables for wb interface in top.sv(proj1)
  bit [WB_ADDR_WIDTH-1:0]  addr;
  logic [WB_DATA_WIDTH-1:0]  data;
  bit we;
  bit [1:0] wb_op; // WB Master operation mode ( READ , WRITE , INTERRUPT)

  rand bit [I2C_ADDR_WIDTH-2:0]  random_slave_addr;
  rand logic [WB_DATA_WIDTH-1:0]  random_data;
  rand bit random_we;
  // rand bit check_for_irq;
  rand bit[3:0] bus_id;
  


  function new(string name=""); 
    super.new(name);
  endfunction : new
  
  virtual function string convert2string();
     return {super.convert2string(),$sformatf("Address:0x%x WE:0x%x Data:0x%p ", this.addr, this.we, this.data)};
  endfunction : convert2string

  //*** Function to initialize the trans variables before passing the transaction to the agent ***//
  function void init_trans_var(bit [WB_ADDR_WIDTH-1:0] addr, bit [WB_DATA_WIDTH-1:0] data=8'h0x0, bit [1:0] wb_op);
    this.addr=addr;
    this.data=data;
    this.wb_op = wb_op;
    if(wb_op) this.we = 0;
    else if(wb_op == 0) this.we = 1;
  endfunction : init_trans_var

  
  function bit compare(wb_transaction rhs);
    return ((this.addr  == rhs.addr ) && 
            (this.data == rhs.data) &&
            (this.we == rhs.we) );
  endfunction : compare


endclass : wb_transaction