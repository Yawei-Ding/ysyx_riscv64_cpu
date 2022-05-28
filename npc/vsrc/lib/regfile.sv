`include "vsrc/lib/define.sv"
module regfile (
  input                         clk,
  input                         wen,
  input        [`REG_ADDRW-1:0] waddr,
  input        [`CPU_WIDTH-1:0] wdata,
  input        [`REG_ADDRW-1:0] raddr1,
  input        [`REG_ADDRW-1:0] raddr2,
  output logic [`CPU_WIDTH-1:0] rdata1,
  output logic [`CPU_WIDTH-1:0] rdata2
);

  reg [`CPU_WIDTH-1:0] rf [`REG_COUNT-1:0];
  always @(posedge clk) begin
    if (wen) rf[waddr] <= wdata;
  end

  always @(*) begin
    if(raddr1 == `REG_ADDRW'b0)
        rdata1 = `CPU_WIDTH'b0;
    else
        rdata1 = rf[raddr1];
  end

  always @(*) begin
    if(raddr2 == `REG_ADDRW'b0)
      rdata2 = `CPU_WIDTH'b0;
    else
      rdata2 = rf[raddr2];
  end

endmodule
