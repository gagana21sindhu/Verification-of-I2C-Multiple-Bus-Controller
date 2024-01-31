//parameter int WB_ADDR_WIDTH = 2;
//parameter int WB_DATA_WIDTH = 8;
//parameter int NUM_I2C_SLAVES = 2;
/*
parameter bit [1:0] CSR = 2'b00;
parameter bit [1:0] DPR = 2'b01;
parameter bit [1:0] CMDR = 2'b10;
parameter bit [1:0] FSMR = 2'b11;*/

typedef enum bit [1:0] {CSR_t=2'b00, DPR_t=2'b01, CMDR_t=2'b10, FSMR_t=2'b11} reg_t;

typedef enum bit {E_E = 1'b1, D_E = 1'b0} enable_t;

typedef enum bit {D_IN = 1'b0, E_IN = 1'b1} interrupt_t;