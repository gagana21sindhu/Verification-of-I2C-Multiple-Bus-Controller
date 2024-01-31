class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));
  ncsu_component#(i2c_transaction) scoreboard;
  i2c_transaction transport_trans; 
  i2cmb_env_configuration configuration;
  i2c_transaction expected_trans;

  bit [I2C_ADDR_WIDTH-1:0] addr;
  bit [I2C_DATA_WIDTH-1:0] write_data[];
  bit [I2C_DATA_WIDTH-1:0] read_data[];
  i2c_op_t op;
  bit [2:0] i2c_state;
  parameter [2:0] detect_start       = 0,
		              detect_addr        = 1,
                  detect_write_data  = 2,
                  detect_read_data   = 3;
          

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction : new

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction : set_configuration

  virtual function void set_scoreboard(ncsu_component #(i2c_transaction) scoreboard);
      this.scoreboard = scoreboard;
  endfunction : set_scoreboard

  //***  The Predictor nb_put called by the WB Agent to pass the monitored transaction ***//
  // This should pass the expected I2C transaction from the received WB transaction to Scoreboard //
  virtual function void nb_put(T trans);
    case(i2c_state)
         detect_start:
            begin
               if(trans.addr == 2 && trans.we == 1 && trans.data[2:0] == 3'b100) begin
                  i2c_state = detect_addr;
               end
            end
         detect_addr:
            begin
               if(trans.addr == 1 && trans.we == 1) begin
                  addr = trans.data >> 1;
                  if(trans.data[0]) begin 
                    $cast(op,1); 
                  end
                  else begin  
                    $cast(op,0); 
                    end 
                  if(trans.data[0]) i2c_state = detect_read_data; 
                  else i2c_state = detect_write_data;

               end
            end
         detect_write_data:
            begin
               //get write data, loop until stop or repeated start bit
               if(trans.addr == 1 && trans.we == 1) begin
                  write_data = new[write_data.size()+1](write_data);
                  write_data[write_data.size()-1] = trans.data;
                  i2c_state = detect_write_data;
               end
               //repeated start bit
               else if(trans.addr == 2 && trans.we == 1 && trans.data[2:0] == 3'b100) begin
                  expected_trans = new;
                  expected_trans.addr = addr;
                  $cast(expected_trans.i2c_op,op);
                  expected_trans.data = write_data;
                  scoreboard.nb_transport(expected_trans,transport_trans);
                  write_data.delete();
                  i2c_state = detect_addr;
               end
               //stop bit
               else if(trans.addr == 2 && trans.we == 1 && trans.data[2:0] == 3'b101) begin
                  expected_trans = new;
                  expected_trans.addr = addr;
                  $cast(expected_trans.i2c_op,op);
                  expected_trans.data = write_data;
                  scoreboard.nb_transport(expected_trans,transport_trans);
                  write_data.delete();
                  i2c_state = detect_start;
               end
            end
         detect_read_data:
            begin
               //get read data, loop until stop or repeated start bit
               if(trans.addr == 1 && trans.we == 0) begin 
                  read_data = new[read_data.size()+1](read_data);
                  read_data[read_data.size()-1] = trans.data;
                  i2c_state = detect_read_data;
               end
               //repeated_start
               else if(trans.addr == 2 && trans.we == 1 && trans.data[2:0] == 3'b100) begin
                  expected_trans = new;
                  expected_trans.addr = addr;
                  $cast(expected_trans.i2c_op,op);
                  expected_trans.data = read_data;
                  scoreboard.nb_transport(expected_trans,transport_trans);
                  read_data.delete();
                  i2c_state = detect_addr;
               end
               //stop
               else if(trans.addr == 2 && trans.we == 1 && trans.data[2:0] == 3'b101) begin
                  expected_trans = new;
                  expected_trans.addr = addr;
                  $cast(expected_trans.i2c_op,op);
                  expected_trans.data = read_data;
                  scoreboard.nb_transport(expected_trans,transport_trans);
                  read_data.delete();
                  i2c_state = detect_start;
               end
            end
         default:
            begin
               i2c_state = detect_start;
            end
      endcase 
  endfunction : nb_put
  
endclass : i2cmb_predictor
