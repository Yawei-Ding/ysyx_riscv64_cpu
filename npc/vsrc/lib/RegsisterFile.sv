module RegsisterFile #(
  REG_COUNT = 1,
  DATA_WIDTH = 1,
  ADDR_WIDTH = $clog2(REG_COUNT)
)(
  input clk,

  input wen,
  input [ADDR_WIDTH-1:0] waddr,
  input [DATA_WIDTH-1:0] wdata,

  input ren,
  input [ADDR_WIDTH-1:0] raddr1,
  input [ADDR_WIDTH-1:0] raddr2,
  output logic [DATA_WIDTH-1:0] rdata1,
  output logic [DATA_WIDTH-1:0] rdata2
);
  reg [DATA_WIDTH-1:0] rf [REG_COUNT-1:0];
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
  end
  
  assign rdata1 = ren? rf[raddr1] : {DATA_WIDTH{1'b0}};
  assign rdata2 = ren? rf[raddr2] : {DATA_WIDTH{1'b0}};

endmodule
