interface uni_if;
  parameter ADDR_W = 32;
  parameter DATA_W = 64;

  logic               valid ;
  logic               ready ;
  logic               reqtyp;
  logic [ADDR_W-1:0]  addr  ;
  logic [DATA_W-1:0]  wdata ;
  logic [DATA_W-1:0]  rdata ;
  logic               cachable;
  logic [1:0]         size  ;

  modport Master(
    output valid, input ready, output reqtyp,   output addr,
    output wdata, input rdata, output cachable, output size
  );

  modport Slave(
    input valid, output ready, input reqtyp,   input addr,
    input wdata, output rdata, input cachable, input size
  );

  // size : 00->byte, 01->half byte, 10->word, 11->double word.

endinterface
