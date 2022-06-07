`include "config.sv"
module regfile (
  input                         i_clk   ,
  input                         i_wen   ,
  input        [`REG_ADDRW-1:0] i_waddr ,
  input        [`CPU_WIDTH-1:0] i_wdata ,
  input        [`REG_ADDRW-1:0] i_raddr1,
  input        [`REG_ADDRW-1:0] i_raddr2,
  output logic [`CPU_WIDTH-1:0] o_rdata1,
  output logic [`CPU_WIDTH-1:0] o_rdata2,
  output logic                  s_a0zero  //use for sim, good trap or bad trap.
);

  reg  [`CPU_WIDTH-1:0] rf [`REG_COUNT-1:0];

  always @(posedge i_clk) begin
    if (i_wen) begin
      if(i_waddr == `REG_ADDRW'b0)
        rf[i_waddr] <= `CPU_WIDTH'b0;
      else
        rf[i_waddr] <= i_wdata;
    end
  end

  assign o_rdata1 = rf[i_raddr1];
  assign o_rdata2 = rf[i_raddr2];

  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
  assign s_a0zero = ~|rf[10]; // if x[10]/a0 is zero, o_a0zero == 1
  import "DPI-C" function void set_reg_ptr(input logic [63:0] a []);
  initial set_reg_ptr(rf);

endmodule
