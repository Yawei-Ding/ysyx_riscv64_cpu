interface uni_if;
  parameter ADDR_W = 32;
  parameter DATA_W = 64;

  logic               valid ;
  logic               ready ;
  logic               reqtyp; // 1: write, 0: read.
  logic [ADDR_W-1:0]  addr  ;
  logic [DATA_W-1:0]  wdata ;
  logic [DATA_W-1:0]  rdata ;
  logic [1:0]         size  ;
  logic [1:0]         resp  ; 

  modport Master(
    output valid, input ready, output reqtyp, output addr,
    output wdata, input rdata, output size,   input  resp
  );

  modport Slave(
    input valid, output ready, input reqtyp, input  addr,
    input wdata, output rdata, input size,   output resp
  );

  // size : 00->byte, 01->half byte, 10->word, 11->double word.

endinterface
