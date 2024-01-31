class i2cmb_reg_tests_generator extends i2cmb_generator;
    `ncsu_register_object(i2cmb_reg_tests_generator)

    wb_transaction wb_trans;
    i2c_transaction i2c_trans;

    ncsu_component #(wb_transaction) wb_agent;
    ncsu_component #(i2c_transaction) i2c_agent;

    bit [WB_DATA_WIDTH-1:0] initial_reg_data[4];
    bit [WB_DATA_WIDTH-1:0] final_reg_data[4];
    bit [WB_DATA_WIDTH-1:0] invalid_addr_data;

    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        wb_trans = new("wb_transaction");
        i2c_trans = new("i2c_transaction");
    endfunction : new

    virtual function void set_agent0(ncsu_component #(wb_transaction) agent);
        this.wb_agent = agent;
    endfunction : set_agent0

    virtual function void set_agent1(ncsu_component #(i2c_transaction) agent);
        this.i2c_agent = agent;
    endfunction : set_agent1

    virtual task run();
        reg_default;
        reg_aliasing;
        reg_access;
        reg_invalid_addr;
        reg_field_accuracy;
        #100000000 $finish;
    endtask : run

  //****************************************************************************************************//
  //*** Directed test for Checking default register values ***//
  task reg_default;
    $display("*****  DEFAULT REGISTER VALUES TEST BEGIN   *****");
    core_reset; // Reset the CORE before reading the values from the register //
    #100ns;
    // Reading the register values
    CSR_read;
    initial_reg_data[0] = wb_trans.data;
    $display("Default CSR value observed: %b", initial_reg_data[0]);
    DPR_read;
    initial_reg_data[1] = wb_trans.data;
    $display("Default DPR value observed: %b", initial_reg_data[1]);
    CMDR_read;
    initial_reg_data[2] = wb_trans.data;
    $display("Default CMDR value observed: %b", initial_reg_data[2]);
    FSMR_read;
    initial_reg_data[3] = wb_trans.data;
    $display("Default FSMR value observed: %b", initial_reg_data[3]);
    if(initial_reg_data[0] == 8'b00000000 &&
       initial_reg_data[1] == 8'b00000000 &&
       initial_reg_data[2] == 8'b10000000 &&
       initial_reg_data[3] == 8'b00000000   ) begin
         $display("RESULTS: PASS");
      end
      else begin
         $display("RESULTS: FAIL");
      end
      $display("*****  DEFAULT REGISTER VALUES TEST END   *****\n"); 
  endtask : reg_default

  task reg_invalid_addr;
    $display("*****  REGISTER INVALID_ADDRESS TEST BEGIN   *****");
    core_reset;
    core_power_up;
    #100ns;
    // Reading the register values after CORE power up
    CSR_read;
    initial_reg_data[0] = wb_trans.data;
    $display("Initial CSR value observed: %b", initial_reg_data[0]);
    DPR_read;
    initial_reg_data[1] = wb_trans.data;
    $display("Initial DPR value observed: %b", initial_reg_data[1]);
    CMDR_read;
    initial_reg_data[2] = wb_trans.data;
    $display("Initial CMDR value observed: %b", initial_reg_data[2]);
    FSMR_read;
    initial_reg_data[3] = wb_trans.data;
    $display("Initial FSMR value observed: %b", initial_reg_data[3]);

    //Writing to invalid address
    wb_trans.init_trans_var(4,8'h0xAA,2'b01);
    wb_agent.bl_put(wb_trans);

    //Reading the register values to see the write did not effect other registers
    CSR_read;
    final_reg_data[0] = wb_trans.data;
    $display("Final CSR value observed: %b", final_reg_data[0]);
    DPR_read;
    final_reg_data[1] = wb_trans.data;
    $display("Final DPR value observed: %b", final_reg_data[1]);
    CMDR_read;
    final_reg_data[2] = wb_trans.data;
    $display("Final CMDR value observed: %b", final_reg_data[2]);
    FSMR_read;
    final_reg_data[3] = wb_trans.data;
    $display("Final FSMR value observed: %b", final_reg_data[3]);

    //Comparing the read values for changes
     if(final_reg_data[0] == 8'b10000000 && // The address of 4 , will be taken as address 0 since the addr width = 2 
       final_reg_data[1] == initial_reg_data[1] && 
       final_reg_data[2] == initial_reg_data[2] && 
       final_reg_data[3] == initial_reg_data[3]   ) begin
         $display("RESULTS: PASS");
      end
      else begin
         $display("RESULTS: FAIL");
      end
    $display("*****  REGISTER INVALID_ADDRESS TEST END   *****\n");
  endtask

  
  //****************************************************************************************************//
  //*** Directed test for Checking Register Aliasing ***//
  // Write to one register and see if other registers effected 
  task reg_aliasing;
    $display("*****  REGISTER ALIASING TEST BEGIN   *****");
    core_reset;
    core_power_up;
    #100ns;
    // Reading the register values after CORE power up
    CSR_read;
    initial_reg_data[0] = wb_trans.data;
    $display("Initial CSR value observed: %b", initial_reg_data[0]);
    DPR_read;
    initial_reg_data[1] = wb_trans.data;
    $display("Initial DPR value observed: %b", initial_reg_data[1]);
    CMDR_read;
    initial_reg_data[2] = wb_trans.data;
    $display("Initial CMDR value observed: %b", initial_reg_data[2]);
    FSMR_read;
    initial_reg_data[3] = wb_trans.data;
    $display("Initial FSMR value observed: %b", initial_reg_data[3]);

    $display("*****  DPR Write check   *****");

    // Writing to DPR register 
    DPR_write(8'h0xAA);

    //Reading the register values to see the DPR write did not effect other registers
    CSR_read;
    final_reg_data[0] = wb_trans.data;
    $display("Final CSR value observed: %b", final_reg_data[0]);
    DPR_read;
    final_reg_data[1] = wb_trans.data;
    $display("Final DPR value observed: %b", final_reg_data[1]);
    CMDR_read;
    final_reg_data[2] = wb_trans.data;
    $display("Final CMDR value observed: %b", final_reg_data[2]);
    FSMR_read;
    final_reg_data[3] = wb_trans.data;
    $display("Final FSMR value observed: %b", final_reg_data[3]);

    //Comparing the read values for changes
    if(final_reg_data[0] == initial_reg_data[0] &&
       final_reg_data[1] == initial_reg_data[1] && // Reading DPR register returns last byte received via I2C bus.
       final_reg_data[2] == initial_reg_data[2] && 
       final_reg_data[3] == initial_reg_data[3]   ) begin
         $display("DPR Write RESULTS: PASS");
      end
      else begin
         $display("DPR Write RESULTS: FAIL");
      end
    $display("*****  REGISTER ALIASING TEST END   *****\n");
  endtask : reg_aliasing

  //****************************************************************************************************//
  //*** Directed test for Checking Register Access Permissions ***//
  // Write to Read Only Register/Fileds should not effect the register/field values 
  task reg_access;
    $display("*****  REGISTER ACCESS TEST BEGIN   *****");
    core_reset;
    core_power_up;
    #100ns;
    // Reading the register values after CORE power up
    CSR_read;
    initial_reg_data[0] = wb_trans.data;
    $display("Initial CSR value observed: %b", initial_reg_data[0]);
    DPR_read;
    initial_reg_data[1] = wb_trans.data;
    $display("Initial DPR value observed: %b", initial_reg_data[1]);
    CMDR_read;
    initial_reg_data[2] = wb_trans.data;
    $display("Initial CMDR value observed: %b", initial_reg_data[2]);
    FSMR_read;
    initial_reg_data[3] = wb_trans.data;
    $display("Initial FSMR value observed: %b", initial_reg_data[3]);

    $display("*****  FSMR Write check   *****");
    FSMR_write(8'h0xAA);
    //Reading the register values to see the FSMR write did not effect it or any other registers
    CSR_read;
    final_reg_data[0] = wb_trans.data;
    $display("Final CSR value observed: %b", final_reg_data[0]);
    DPR_read;
    final_reg_data[1] = wb_trans.data;
    $display("Final DPR value observed: %b", final_reg_data[1]);
    CMDR_read;
    final_reg_data[2] = wb_trans.data;
    $display("Final CMDR value observed: %b", final_reg_data[2]);
    FSMR_read;
    final_reg_data[3] = wb_trans.data;
    $display("Final FSMR value observed: %b", final_reg_data[3]);

    //Comparing the read values for changes
    if(final_reg_data[0] == initial_reg_data[0] &&
       final_reg_data[1] == initial_reg_data[1] && 
       final_reg_data[2] == initial_reg_data[2] && 
       final_reg_data[3] == initial_reg_data[3]   ) begin
         $display("FSMR Write RESULTS: PASS");
      end
      else begin
         $display("FSMR Write RESULTS: FAIL");
      end

    $display("*****  CMDR Write check   *****");
    // Writing to CMDR register 
    CMDR_write(8'b11101010);
    $display("CMDR Write value = %b",8'b11101010);
    $display("Only Last three fileds are R/W");
    //Reading the register values to see the CMDR write did not effect other registers
    CSR_read;
    final_reg_data[0] = wb_trans.data;
    $display("Final CSR value observed: %b", final_reg_data[0]);
    DPR_read;
    final_reg_data[1] = wb_trans.data;
    $display("Final DPR value observed: %b", final_reg_data[1]);
    CMDR_read;
    final_reg_data[2] = wb_trans.data;
    $display("Final CMDR value observed: %b", final_reg_data[2]);
    FSMR_read;
    final_reg_data[3] = wb_trans.data;
    $display("Final FSMR value observed: %b", final_reg_data[3]);

    //Comparing the read values for changes
    if(final_reg_data[0] == initial_reg_data[0] &&
       final_reg_data[1] == initial_reg_data[1] && 
       // ERR bit will be enabled because there is no BUS set
       // and only the last 3 bits should be written as the rest fileds are RO
       final_reg_data[2] == 8'b00010010 && 
       final_reg_data[3] == initial_reg_data[3]   ) begin
         $display("CMDR Write RESULTS: PASS");
      end
      else begin
         $display("CMDR Write RESULTS: FAIL");
      end

      $display("*****  REGISTER ACCESS TEST END   *****\n");
  endtask : reg_access

  //****************************************************************************************************//
  //*** Directed test for Checking Register Field Accuracy ***//
  // Check if the Register fields actually do what they are advertised to do in the spec
  task reg_field_accuracy();
    $display("*****  REGISTER FIELDS ACCURACY TEST BEGIN   *****");
    core_reset;
    core_power_up;

    set_busID;
    set_bus;
    send_start;
    // Reading CSR to check BB , BC and BusID
    CSR_read;
    final_reg_data[0] = wb_trans.data;
    $display("Final CSR value observed: %b", final_reg_data[0]);

    // Reading CMDR to check DON bit 
    CMDR_read;
    final_reg_data[2] = wb_trans.data;
    $display("CMDR value after START cmnd with BUS Capture: %b", final_reg_data[2]);

    //Checking the CSR and CMDR fields for accuracy
    //BB and BC should be enable 
    //Bus ID should be 0
    if(final_reg_data[0] == 8'b11110000)  $display("CSR Field Accuracy RESULTS: PASS");
    else $display("CSR Field Accuracy RESULTS: FAIL");

    if(final_reg_data[2] == 8'b10000100)  $display("CMDR Field Accuracy RESULTS: PASS");
    else $display("CMDR Field Accuracy RESULTS: FAIL");

    $display("*****  REGISTER FIELDS ACCURACY TEST END   *****\n");
  endtask : reg_field_accuracy


  task core_power_up;
    wb_trans.init_trans_var(`CSR, 8'h0xC0,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : core_power_up

  task core_reset;
    wb_trans.init_trans_var(`CSR, 8'h0x00,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : core_reset

 task set_busID;
    wb_trans.init_trans_var(`DPR,8'h0x00,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : set_busID

 task set_bus;
    wb_trans.init_trans_var(`CMDR, `SETBUS,2'b01);
    wb_agent.bl_put(wb_trans);
    wb_trans.init_trans_var(`CMDR,,2'b10);
    wb_agent.bl_put(wb_trans);
  endtask : set_bus

  task send_start;
    wb_trans.init_trans_var(`CMDR,`START,2'b01);
    wb_agent.bl_put(wb_trans);
    wb_trans.init_trans_var(`CMDR,,2'b10);
    wb_agent.bl_put(wb_trans);
  endtask : send_start
  
  task set_slave_address_mode(bit [6:0]slave_addr,bit we);
    bit [7:0] slave_addr_we = {slave_addr,we};
    wb_trans.init_trans_var(`DPR, slave_addr_we,2'b01);
    wb_agent.bl_put(wb_trans);
    wb_trans.init_trans_var(`CMDR,`WRITE,2'b01);
    wb_agent.bl_put(wb_trans);
    wb_trans.init_trans_var(`CMDR,,2'b10);
    wb_agent.bl_put(wb_trans);
  endtask : set_slave_address_mode

  task send_stop;
    wb_trans.init_trans_var(`CMDR,`STOP,2'b01);
    wb_agent.bl_put(wb_trans);
    wb_trans.init_trans_var(`CMDR,,2'b10);
    wb_agent.bl_put(wb_trans);
  endtask : send_stop

  task CSR_read;
    wb_trans.init_trans_var(`CSR,,2'b00);
    wb_agent.bl_put(wb_trans);
  endtask : CSR_read

  task CSR_write(bit [WB_DATA_WIDTH-1:0] data);
    wb_trans.init_trans_var(`CSR,data,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : CSR_write

  task DPR_read;
    wb_trans.init_trans_var(`DPR,,2'b00);
    wb_agent.bl_put(wb_trans);
  endtask : DPR_read

  task DPR_write(bit [WB_DATA_WIDTH-1:0] data);
    wb_trans.init_trans_var(`DPR,data,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : DPR_write

  task CMDR_read;
    wb_trans.init_trans_var(`CMDR,,2'b00);
    wb_agent.bl_put(wb_trans);
  endtask : CMDR_read

  task CMDR_write(bit [WB_DATA_WIDTH-1:0] data);
    wb_trans.init_trans_var(`CMDR,data,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : CMDR_write

 task FSMR_read;
    wb_trans.init_trans_var(`FSMR,,2'b00);
    wb_agent.bl_put(wb_trans);
  endtask : FSMR_read

  task FSMR_write(bit [WB_DATA_WIDTH-1:0] data);
    wb_trans.init_trans_var(`FSMR,data,2'b01);
    wb_agent.bl_put(wb_trans);
  endtask : FSMR_write



endclass : i2cmb_reg_tests_generator