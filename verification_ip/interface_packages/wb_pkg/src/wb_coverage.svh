class wb_coverage extends ncsu_component#(.T(wb_transaction));

  wb_configuration configuration;

   bit [WB_ADDR_WIDTH-1:0] wb_addr;
   bit we;
   bit [WB_DATA_WIDTH-1:0] wb_data;
   bit [WB_DATA_WIDTH-1:0] reg_data;
   reg_t reg_type;
   bit [WB_ADDR_WIDTH-1:0] reg_addr;

   covergroup wb_transaction_cg;
      option.per_instance = 1;
      option.name = get_full_name();
      wb_addr : coverpoint wb_addr;
      wb_data : coverpoint wb_data {bins data = {[0:32],[64:128]};}
      we : coverpoint we {bins read = {1'b1}; bins write = {1'b0};}
      wb_data_x_we : cross wb_data, we;
   endgroup

  covergroup reg_cg;
    option.per_instance = 1;
    option.name = get_full_name();
    reg_addr : coverpoint reg_addr {bins valid [4] = {0, 1, 2, 3};}
    regCSR: coverpoint reg_type {bins CSRbin = {`CSR};}
    dataCSR: coverpoint reg_data {bins core_enable = {8'hC0};}
    
    regCMDR: coverpoint reg_type {bins CMDRbin = {`CMDR};}
    dataCMDR: coverpoint reg_data
    {
      bins SET_BUS = {8'h06};
      bins START = {8'h04};
      bins WRITE_t = {8'h01};
      bins READ_NAK = {8'h03};
      bins READ_ACK = {8'h02};
      bins STOP = {8'h05};
    }

  // Cross Checks
      csr_x_data: cross regCSR,dataCSR;
      cmdr_x_data: cross regCMDR, dataCMDR;

  endgroup
 
  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    wb_transaction_cg = new;
    reg_cg = new;
  endfunction

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    wb_addr = trans.addr;
    we = trans.we;
    wb_data = trans.data;
    reg_addr = trans.addr;
    reg_type = reg_t'(trans.addr);
    reg_data = trans.data;
    wb_transaction_cg.sample();
    reg_cg.sample();
  endfunction

endclass : wb_coverage
