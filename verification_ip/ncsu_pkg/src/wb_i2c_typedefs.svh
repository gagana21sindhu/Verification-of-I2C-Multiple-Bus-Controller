parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;

typedef enum bit {WRITE=0,READ=1} i2c_op_t;

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_SLAVES = 2;
typedef enum bit [1:0] {WB_READ = 2'b00, WB_WRITE = 2'b01, WB_INT = 2'b10} wb_op_t;

//Byte level FSM commands
`define START 8'bxxxxx100
`define STOP 8'bxxxxx101
`define RWACK 8'bxxxxx010
`define RWNACK 8'bxxxxx011 
`define WRITE 8'bxxxxx001 
`define SETBUS 8'bxxxxx110 
`define WAIT 8'bxxxxx000 

//Register blocks
`define CSR 3'b000
`define DPR 3'b001
`define CMDR 3'b010
`define FSMR 3'b011


