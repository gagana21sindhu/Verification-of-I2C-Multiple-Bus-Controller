class i2cmb_generator extends ncsu_component#(.T(wb_transaction));
  `ncsu_register_object(i2cmb_generator)

  wb_transaction wb_trans;
  i2c_transaction i2c_trans;

  ncsu_component #(wb_transaction) wb_agent;
  ncsu_component #(i2c_transaction) i2c_agent;

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

  //****************************************************************************************************//
  //***  Generator run task that executes the default test flow ***//
  virtual task run();
    fork
      i2c_agent.bl_put(i2c_trans);
    join_none
    #500ns;
    core_power_up;
    set_busID;
    set_bus;
    i2c_master_tx; // Continuous Write transactions
    #1000ns;
    i2c_master_rx; // Continuous Read transactions
    #1000ns;
    i2c_combined;  // Alternate Write and Read Transactions
    #100000000 $finish;
  endtask : run


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

  //*****************************************************************************************************************************************//
  //  Task generating WB and I2C transactions for Continuous Write Operation //
  task i2c_master_tx;
    automatic bit [I2C_DATA_WIDTH-1:0] write_value = 8'h0x00;
    $display("********                            Started I2C_Master as Transmitter for Continuous Write Operation of Values (0 to 31) on the I2C Bus                    *******");
    fork
      begin
        i2c_agent.bl_put(i2c_trans);
      end
      begin
        send_start;
        set_slave_address_mode(7'h0x39,1'b0);
        for(int i=0;i<=31;i++)
        begin
          wb_trans.init_trans_var(`DPR,write_value,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,`WRITE,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Continuous Write Operation ", $sformatf("%d , value sent by generator : %d",i+1,write_value), NCSU_NONE);
          write_value = write_value + 1;
        end
        send_stop;
        $display("***************                                    Completed Continuous Write Operation                              **************\n");
      end
    join
  endtask : i2c_master_tx



  //*****************************************************************************************************************************************//
  //  Task generating WB and I2C transactions for Continuous Read Operation //
  task i2c_master_rx;
  automatic bit[I2C_DATA_WIDTH-1:0] i2c_read[];
  $display("********                             Started I2C_Master as Receiver for Continuous Read Operation of Values (100 to 131) on the I2C Bus                      *******");
    i2c_read= new[32];
		foreach(i2c_read[i]) i2c_read[i] = 100+i;
    i2c_trans.init_read_data(i2c_read);
    fork
      begin
        i2c_agent.bl_put(i2c_trans);
      end
      begin
        send_start;
        set_slave_address_mode(7'h0x39,1'b1);
        for(int i=0;i<=30;i++)
        begin
          wb_trans.init_trans_var(`CMDR,`RWACK,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`DPR,,2'b00);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Continuous Read Operation ", $sformatf("%d ,value received by generator : %d",i+1,wb_trans.data), NCSU_NONE);
        end
        wb_trans.init_trans_var(`CMDR,`RWNACK,2'b01);
        wb_agent.bl_put(wb_trans);
        wb_trans.init_trans_var(`CMDR,,2'b10);
        wb_agent.bl_put(wb_trans);
        wb_trans.init_trans_var(`DPR,,2'b00);
        wb_agent.bl_put(wb_trans);
        //ncsu_info("( Gen ) Continuous Read Operation ", $sformatf("%d ,value received by generator : %d",32,wb_trans.data), NCSU_NONE);
        send_stop;
        $display("********************                       Completed Continuous Read Operation                       **************************\n");
      end
    join
  endtask : i2c_master_rx


  //*****************************************************************************************************************************************//
  //  Task generating WB and I2C transactions for Alternate Write and Read Operation //
  task i2c_combined;
    automatic bit [I2C_DATA_WIDTH-1:0] write_value = 8'h0x40;
    automatic int i=0;
    automatic bit[I2C_DATA_WIDTH-1:0] i2c_read[];
    $display("************                           Started I2C_Combined_format Transmission with alternate Write(64 to 127) and Read(63 to 0) on the I2C Bus                         ****************");
    for(i=0;i<64;i++) 
    begin
      i2c_read=new[1];
		  i2c_read[0] = 63-i;
      i2c_trans.init_read_data(i2c_read);
      fork
        begin
          i2c_agent.bl_put(i2c_trans);
        end
        begin
          send_start;
          set_slave_address_mode(7'h0x39,1'b0);

          wb_trans.init_trans_var(`DPR,write_value,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,`WRITE,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Alternate Write Operation ", $sformatf("%d , value sent by generator : %d",i+1,write_value), NCSU_NONE);
          write_value = write_value + 1;

          send_start;
          set_slave_address_mode(7'h0x39,1'b1);

          wb_trans.init_trans_var(`CMDR,`RWNACK,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`DPR,,2'b00);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Alternate Read Operation ", $sformatf("%d ,value received by generator : %d",i+1,wb_trans.data), NCSU_NONE);
        end
      join
    end
    send_stop;
    $display("***********                  Completed 64 Alterate Write and Read Operations              *****************\n");
  endtask : i2c_combined


//*****************************************************************************************************************************************//
  //  Task generating WB and I2C transactions for Random Continuous Write Operation //
  task i2c_rand_tx;
    automatic bit [I2C_DATA_WIDTH-1:0] write_value;
    $display("********                            Started I2C_Master as Transmitter for Continuous Write Operation of 20 Random Values on the I2C Bus                    *******");
    fork
      begin
        i2c_agent.bl_put(i2c_trans);
      end
      begin
        send_start;
        set_slave_address_mode(7'h0x39,1'b0);
        for(int i=0;i<20;i++)
        begin
          assert(wb_trans.randomize());
          write_value = wb_trans.random_data;
          wb_trans.init_trans_var(`DPR,write_value,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,`WRITE,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
        end
        send_stop;
        $display("***************                                    Completed Continuous Random Write Operation                              **************\n");
      end
    join
  endtask : i2c_rand_tx


  //*****************************************************************************************************************************************//
  //  Task generating WB and I2C transactions for Random Continuous Read Operation //
  task i2c_rand_rx;
  automatic bit[I2C_DATA_WIDTH-1:0] i2c_read[];
  $display("********                             Started I2C_Master as Receiver for Continuous Read Operation of 20 Random Values on the I2C Bus                      *******");
    i2c_read= new[20];
		for (int i=0;i<20;i++)
    begin 
      assert(i2c_trans.randomize());
      i2c_read[i] = i2c_trans.random_read_data;
    end
    i2c_trans.init_read_data(i2c_read);
    fork
      begin
        i2c_agent.bl_put(i2c_trans);
      end
      begin
        send_start;
        set_slave_address_mode(7'h0x39,1'b1);
        for(int i=0;i<=18;i++)
        begin
          wb_trans.init_trans_var(`CMDR,`RWACK,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`DPR,,2'b00);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Continuous Read Operation ", $sformatf("%d ,value received by generator : %d",i+1,wb_trans.data), NCSU_NONE);
        end
        wb_trans.init_trans_var(`CMDR,`RWNACK,2'b01);
        wb_agent.bl_put(wb_trans);
        wb_trans.init_trans_var(`CMDR,,2'b10);
        wb_agent.bl_put(wb_trans);
        wb_trans.init_trans_var(`DPR,,2'b00);
        wb_agent.bl_put(wb_trans);
        //ncsu_info("( Gen ) Continuous Read Operation ", $sformatf("%d ,value received by generator : %d",32,wb_trans.data), NCSU_NONE);
        send_stop;
        $display("********************                       Completed Random Continuous Read Operation                       **************************\n");
      end
    join
  endtask : i2c_rand_rx


  //*****************************************************************************************************************************************//
  //  Task generating WB and I2C transactions for Random Alternate Write and Read Operation to random slaves//
  task i2c_rand_alt;
    automatic bit [I2C_DATA_WIDTH-1:0] write_value;
    automatic bit [I2C_ADDR_WIDTH-2:0] i2c_slave;
    automatic bit[I2C_DATA_WIDTH-1:0] i2c_read[];
    $display("************            Started Random Alternate Write and Read Operation to random slaves                                      ****************");
    for(int i=0;i<1000;i++) 
    begin
      i2c_read=new[1];
		  assert(i2c_trans.randomize());
      i2c_read[0] = i2c_trans.random_read_data;
      i2c_trans.init_read_data(i2c_read);
      fork
        begin
          i2c_agent.bl_put(i2c_trans);
        end
        begin
          send_start;
          assert(wb_trans.randomize());
          write_value = wb_trans.random_data;
          i2c_slave = wb_trans.random_slave_addr;
          set_slave_address_mode(i2c_slave,1'b0);

          wb_trans.init_trans_var(`DPR,write_value,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,`WRITE,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Alternate Write Operation ", $sformatf("%d , value sent by generator : %d",i+1,write_value), NCSU_NONE);

          send_start;
          set_slave_address_mode(i2c_slave,1'b1);

          wb_trans.init_trans_var(`CMDR,`RWNACK,2'b01);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`CMDR,,2'b10);
          wb_agent.bl_put(wb_trans);
          wb_trans.init_trans_var(`DPR,,2'b00);
          wb_agent.bl_put(wb_trans);
          //ncsu_info("( Gen ) Alternate Read Operation ", $sformatf("%d ,value received by generator : %d",i+1,wb_trans.data), NCSU_NONE);
        end
      join
    end
    send_stop;
    $display("***********                  Completed Random Alternate test              *****************\n");
  endtask : i2c_rand_alt



endclass : i2cmb_generator