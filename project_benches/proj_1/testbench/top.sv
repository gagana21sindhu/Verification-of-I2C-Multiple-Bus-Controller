`timescale 1ns / 10ps

//Byte level FSM commands
`define START 'b100
`define STOP 'b101
`define RWACK 'b010
`define RWNACK 'b011
`define WRITE 'b001
`define SETBUS 'b110
`define WAIT 'b000

//Register blocks
`define CSR 'b00
`define DPR 'b01
`define CMDR 'b10



module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;


bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;


// ****************************************************************************
// Clock generator
initial 
begin: clk_gen
	clk = 0;
	forever #5ns clk = ~clk;
end

// ****************************************************************************
// Reset generator
initial
begin : rst_gen
	#113ns rst = ~rst;
end


// ****************************************************************************
// Monitor I2C and display transfers in the transcript
initial 
begin : monitor_i2c_bus
	bit [I2C_ADDR_WIDTH-1:0] I2C_slave_addr;
	bit [I2C_DATA_WIDTH-1:0] I2C_data[];
	bit I2C_op;
	
	forever begin 
		i2c_bus.monitor(I2C_slave_addr, I2C_op, I2C_data);
		if (I2C_op==1'b0) begin
		    for(int i=0;i<I2C_data.size();i++)
			begin
		        $display("I2C_BUS WRITE Transfer: Addr: %h, Data: %d\n",I2C_slave_addr,I2C_data[i]);
			end
		end
		else if (I2C_op==1'b1) begin
			for(int i=0;i<I2C_data.size();i++)
			begin
			$display("I2C_BUS READ Transfer: Addr: %h, Data: %d\n",I2C_slave_addr,I2C_data[i]);
			end
		end
	end
end : monitor_i2c_bus


// ****************************************************************************
//Monitor WB 
initial 
begin : wb_monitoring
	logic [WB_ADDR_WIDTH] wb_mon_addr;
	logic [WB_DATA_WIDTH] wb_mon_data;
	logic wb_mon_we;	
	forever begin 
	#2ns wb_bus.master_monitor(wb_mon_addr,wb_mon_data,wb_mon_we);		
	end
end : wb_monitoring


// ****************************************************************************
// Interrupt detect by WB and clearing the irq
task interrupt_detect;
	automatic bit [WB_DATA_WIDTH-1:0] cmdr_read;
	while(irq == 1'b0) @(posedge clk); 
	wb_bus.master_read(`CMDR,cmdr_read);
endtask: interrupt_detect


// ****************************************************************************
// I2C_Master_Transmitter Task
task i2c_master_tx ;
	automatic bit [I2C_DATA_WIDTH-1:0] write_value = 8'h0x00;
	$display("********  Started I2C_Master as Transmitter for Continuous Write Operation of Values (0 to 31) on the I2C Bus    *******\n");

	wb_bus.master_write(`CMDR,`START);
	//$display("START SENT");
	interrupt_detect;
	wb_bus.master_write(`DPR,8'h0x72); // slave address = 0x39 , r/wbar = 0
	wb_bus.master_write(`CMDR,`WRITE);
	//$display("Slave address SET and in Write mode");
	interrupt_detect;
	for(int i=0;i<=31;i++)
	begin
		
		wb_bus.master_write(`DPR,write_value);
		wb_bus.master_write(`CMDR,`WRITE);
		interrupt_detect;
		write_value = write_value + 1;
	end
	wb_bus.master_write(`CMDR,`STOP);
	//$display("STOP SENT");
	interrupt_detect;
	$display("********  Completed Continuous Write Operation *********\n");
	
endtask: i2c_master_tx


task i2c_master_rx; 
	automatic bit [I2C_DATA_WIDTH-1:0] read_value;
	$display("********  Started I2C_Master as Receiver for Continuous Read Operation of Values (100 to 131) on the I2C Bus    *******\n");
	wb_bus.master_write(`CMDR,`START);
	//$display("START SENT");
	interrupt_detect;
	wb_bus.master_write(`DPR,8'h0x73); // slave address = 0x39 , r/wbar = 1
	wb_bus.master_write(`CMDR,`WRITE);
	//$display("Slave address SET and in Read mode");
	interrupt_detect;
	for(int i=0;i<=30;i++)
	begin
		wb_bus.master_write(`CMDR,`RWACK);
		interrupt_detect;
		wb_bus.master_read(`DPR,read_value);
	end
	wb_bus.master_write(`CMDR,`RWNACK);
	interrupt_detect;
	//$display("Read with NACK before the STOP");
	wb_bus.master_read(`DPR,read_value);
	//$display("Read value : %h",read_value);
	wb_bus.master_write(`CMDR,`STOP);
	//$display("STOP SENT");
	interrupt_detect;
	$display("********  Completed Continuous Read Operation *********\n");
endtask: i2c_master_rx


task i2c_combined_format;
	automatic bit [I2C_DATA_WIDTH-1:0] write_value = 8'h0x40;
	automatic bit [I2C_DATA_WIDTH-1:0] read_value;
	$display("********  Started I2C_Combined_format Transmission with alternate Write(64 to 127) and Read(63 to 0) on the I2C Bus    *******\n");
	//$display("Starting the 64 alternate tansfers");
	for(int i=0;i<64;i++) begin
 		$display("The Alternate tansfer : %d\n",i);
		wb_bus.master_write(`CMDR,`START);
		//$display("START SENT");
		interrupt_detect;
				
		wb_bus.master_write(`DPR,8'h0x72);
		wb_bus.master_write(`CMDR,`WRITE);
		//$display("Slave address SET and in Write mode");
		interrupt_detect;
		
		wb_bus.master_write(`DPR,write_value);
		wb_bus.master_write(`CMDR,`WRITE);
		interrupt_detect;
		write_value = write_value + 1;
		
		wb_bus.master_write(`CMDR,`START);
		//$display("START SENT");
		interrupt_detect;

		wb_bus.master_write(`DPR,8'h0x73);
		wb_bus.master_write(`CMDR,`WRITE);
		//$display("Slave address SET and in Read mode");
		interrupt_detect;
		
		wb_bus.master_write(`CMDR,`RWNACK);
		//$display("Read with NACK before the Repeated Start");
		interrupt_detect;

		wb_bus.master_read(`DPR,read_value);		 		
  	end
 	wb_bus.master_write(`CMDR,`STOP);
	//$display("STOP SENT");
  	interrupt_detect;
	$display("********  Completed 64 Alterate Write and Read Operations *********\n");
endtask:i2c_combined_format


initial 
begin: I2C_Generator
	automatic int j=0;
	bit op;
	bit transfer_complete;
	bit [I2C_DATA_WIDTH-1:0] write_data [];
	bit [I2C_DATA_WIDTH-1:0] read_data [];
	bit i2c_combined = 0;
	forever begin 
		i2c_bus.wait_for_i2c_transfer(op,write_data);
		//$display("Wait_for_i2c_transfer detected and returned in I2C_Slave_simulate");
		if(op == 1) 
		begin
			$display("I2C_Generator detected Read Operation\n");
			if(i2c_combined == 0)
			begin
				$display("Provided Read Data For Continuous Read started\n");
				read_data = new[32];
				foreach(read_data[i]) read_data[i] = 100+i;
				i2c_bus.provide_read_data(read_data,transfer_complete);
				i2c_combined = 1;
			end		
		    else begin 
				$display("Provided Read Data For Alternate Read started for transfer :%d\n",j);
				read_data=new[1];
				read_data[0] = 63-j;
				i2c_bus.provide_read_data(read_data,transfer_complete);
				j++;
			end
		end
	end
end : I2C_Generator

	
initial 
begin : test_flow
	#500ns;
	$display("********     I2C_if Verification Test started          ******\n");
	wb_bus.master_write(`CSR,8'h0xC0);   
	wb_bus.master_write(`DPR,8'h00); 	//Bus ID
	wb_bus.master_write(`CMDR,`SETBUS);	//Set Bus Command
	//$display("DUT powered and SETBUS");

	interrupt_detect;
	//$display("i2c_master_tx called in test_flow");
	i2c_master_tx;
	#1000ns;
	
	//$display("i2c_master_rx called in test_flow");
	i2c_master_rx;
	#1000ns;
	
	//$display("i2c_combined_format called in test_flow");
	i2c_combined_format;
	$display("********     I2C_if Verification Test Complete          ******\n");
$finish;
end:test_flow

			
		

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

// ****************************************************************************
// Instantiate the I2C master Bus Functional Model
i2c_if #(
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH))
i2c_bus(
    .scl(scl),
    .sda(sda)
);


endmodule
