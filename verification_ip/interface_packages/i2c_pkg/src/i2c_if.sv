`timescale 1ns / 10ps
import ncsu_pkg::*;
import i2c_pkg::*;
interface i2c_if #(
	int I2C_ADDR_WIDTH =7,
	int I2C_DATA_WIDTH =8
	)
(
//*********  I2C Interface Signals  ***********//
input scl,
inout triand sda
);

//********* I2C Operation mode enum ***********//
//typedef enum {WRITE, READ} i2c_op_t;
i2c_op_t operation; 


//********* Variables ************//
bit start, stop;                          // Start and Stop monitoring bits 
bit ack = 1;                              // ack monitoring bit 
bit sda_oe = 0;                           // I2C SDA output enable bit
bit read_data_bit;                        // I2C slave read data written on SDA
int current_write_data_size;
int current_read_data_size;
int current_data_size;
bit [I2C_ADDR_WIDTH-1:0] mon_addr;    
bit [I2C_DATA_WIDTH-1:0] mon_data[];

int count;
bit[3:0] num_byte;


always @(posedge scl) begin
    count++;
end

assign sda = sda_oe?(ack||read_data_bit): 1'bz;   // Tristate of SDA 

assign num_byte = (count) % 9;


//********* START Monitor ***********//
always@(negedge sda) 
	begin : detect_start
	if (scl == 1) begin
	start = 1;
	end
	end

//********* STOP Monitor ***********//
always@(posedge sda)
	begin : detect_stop
	if (scl == 1) begin
	stop = 1;
	end
	end

//**************************************************************************************************************//
//*******                      wait_for_i2c_transfer task definition                                       *****//
// Monitors for the START condition on SCL, receives the SLAVE ADDRESS & 
// R/W bit
// Returns if detected READ mode
// Continues to read the data being written on SDA by Master in WRITE Mode
// **************************************************************************************************************//
task wait_for_i2c_transfer(
			   output i2c_op_t op, 
			   output bit [I2C_DATA_WIDTH-1:0] write_data []
			  );
	bit [I2C_DATA_WIDTH-1:0] write_data_buffer; 

	// waiting for START condition and then reset START and STOP Monitor bit //
	wait(start)                                                   	
	#1ns
	start = 0;stop = 0;
	
	// Reading the SLAVE Address //
	for (int i = 0; i < 7; i++) begin
  		@(posedge scl) mon_addr[I2C_ADDR_WIDTH-1-i] = sda;    
	end
	
	// Reading the R/W Operation mode //
	@(posedge scl);                                              
	if (sda == 0) begin
		op = WRITE;
	end 
	else begin
		op = READ;
	end
	
	operation = op;

	// Capturing the SDA line to send ack for the recieved address //
	@(negedge scl);                   
	sda_oe = 1;
	ack = 0;
	
	// Returning if in READ mode to call the provide_read_data and holding
	// the SDA Line to place the read data //
	if(op == READ) return;
	
	// Releasing the SDA line if WRITE Mode // 
	@(negedge scl);
	sda_oe =0;
	 

	// Starting parallel process to read the SDA line for all written data
	// until STOP or Repeated Start is Recieved //
	fork 
	begin: write_data_capture
		while(1) begin
		repeat(I2C_DATA_WIDTH) begin
		@(posedge scl);
		write_data_buffer = {write_data_buffer,sda};
		end 
			
		current_write_data_size = write_data.size();
		write_data = new[current_write_data_size+1](write_data);
                write_data[current_write_data_size] = write_data_buffer;
			
		current_data_size = mon_data.size();
		mon_data = new[current_data_size+1](mon_data);
                mon_data[current_data_size] = write_data_buffer;
			
		@(negedge scl);
		sda_oe = 1;
		ack = 0;
		@(negedge scl);
		sda_oe = 0;
		end 
	end : write_data_capture
		
	begin: Start_Monitor
	wait(start);
	end
		
	begin: Stop_Monitor 
	wait (stop);
	end 
		
	join_any
	disable fork;
	
endtask : wait_for_i2c_transfer 


//***************************************************************************************************************//
//*******                      provide_read_data task definition                                            *****//
// Task called by generator to provide the read data in READ Mode
// **************************************************************************************************************//

task provide_read_data ( 
			input bit [I2C_DATA_WIDTH-1:0] read_data [],
			output bit transfer_complete
			);
	automatic int read_byte_counter= 0;
	bit [I2C_DATA_WIDTH-1:0] read_data_buffer; 
	
	while(read_byte_counter!=read_data.size())
	begin
		for(int i=0;i<I2C_DATA_WIDTH;i++)
		begin
		@(negedge scl) read_data_bit = read_data[read_byte_counter][I2C_DATA_WIDTH-1-i];
		read_data_buffer = {read_data_buffer,read_data_bit};
		end
		
		current_data_size = mon_data.size();
		mon_data = new[current_data_size+1](mon_data);
        mon_data[current_data_size] = read_data_buffer;
		
		// Releasing SDA line to recieve acknowledge from Master//	
		@(negedge scl); 
		sda_oe = 0;

		// Checking for ack and taking back the SDA line //
		@(posedge scl);
		if(sda==0) begin
			sda_oe = 1;
			read_byte_counter++; // increment counter to receive next byte
		end
		else begin 
		break;                       // break if no ackowledge from master
		end
	end
	
	// Checking for Repeated START or STOP if full Read data sent or
	// Received NACK from Master 
	if (read_byte_counter==read_data.size() || sda == 1'b1) begin
	wait (start || stop);
	end
	
	transfer_complete = 1;
endtask :provide_read_data 



// ******** I2C Bus Monitor Task ******** //
task monitor ( 
			  output bit [I2C_ADDR_WIDTH-1:0] addr, 
			  output i2c_op_t op, 
			  output bit [I2C_DATA_WIDTH-1:0] data []
			  );
	wait(start);          // wait for Start
	wait(!start);	      // wait for Start acknowledge from wait_for_i2c_transfer
	wait(start || stop);  // wait for Repeated Start or Stop

	// Sample the data from the transmission
	addr = mon_addr; 
	op = operation;
	data = mon_data;
	mon_data.delete();
	
endtask : monitor

endinterface 
			

	
	
	
	

