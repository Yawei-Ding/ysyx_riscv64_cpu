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

  assign rf[0] = `CPU_WIDTH'b0; // x[0] must be inital, and it can never be written.

  generate                      // x[1]-x[31]:
    for(genvar i=1; i<`REG_COUNT; i=i+1 )begin: regfile
      always @(posedge i_clk) begin
        if (i_wen && i_waddr == i) begin
          rf[i] <= i_wdata;
        end
      end
    end
  endgenerate

  assign o_rdata1 = rf[i_raddr1];
  assign o_rdata2 = rf[i_raddr2];

  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
  assign s_a0zero = ~|rf[10]; // if x[10]/a0 is zero, o_a0zero == 1
  import "DPI-C" function void set_reg_ptr(input logic [63:0] a []);
  initial set_reg_ptr(rf);

endmodule
