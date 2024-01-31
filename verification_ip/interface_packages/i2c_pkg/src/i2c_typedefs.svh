  parameter int I2C_ADDR_SIZE = 7;
  parameter int I2C_DATA_SIZE = 8;

  typedef enum bit {WRITE=1'b0,READ=1'b1} i2c_op_t;
