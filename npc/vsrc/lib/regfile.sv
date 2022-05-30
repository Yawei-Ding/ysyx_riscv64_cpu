`include "vsrc/lib/define.sv"
module regfile (
  input                         clk,
  input                         wen,
  input        [`REG_ADDRW-1:0] waddr,
  input        [`CPU_WIDTH-1:0] wdata,
  input        [`REG_ADDRW-1:0] raddr1,
  input        [`REG_ADDRW-1:0] raddr2,
  output logic [`CPU_WIDTH-1:0] rdata1,
  output logic [`CPU_WIDTH-1:0] rdata2,
  output logic                  a0zero  //use for sim, good trap or bad trap.
);

  assign a0zero = ~|rf[10]; // if x[10]/a0 is zero, a0zero == 1

  reg [`CPU_WIDTH-1:0] rf [`REG_COUNT-1:0];
  always @(posedge clk) begin
    if (wen) begin
      if(waddr == `REG_ADDRW'b0)
        rf[waddr] <= `CPU_WIDTH'b0;
      else
        rf[waddr] <= wdata;
    end
  end

  assign rdata1 = rf[raddr1];
  assign rdata2 = rf[raddr2];

  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
  import "DPI-C" function void set_reg_ptr(input logic [63:0] a []);
  initial set_reg_ptr(rf);

endmodule
