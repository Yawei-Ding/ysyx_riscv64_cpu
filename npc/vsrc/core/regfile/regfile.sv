`include "defines.sv"
module regfile (
  input                         i_clk   ,
  input                         i_rst_n ,

  // from wbu:
  input                         i_wen   ,
  input        [`REG_ADDRW-1:0] i_waddr ,
  input        [`CPU_WIDTH-1:0] i_wdata ,

  // from idu:
  input        [`REG_ADDRW-1:0] i_raddr1,
  input        [`REG_ADDRW-1:0] i_raddr2,
  output logic [`CPU_WIDTH-1:0] o_rdata1,
  output logic [`CPU_WIDTH-1:0] o_rdata2,
  output logic                  s_a0zero,  //use for sim, good trap or bad trap.

  // difftest sim signals:
  output       [`CPU_WIDTH-1:0] s_regs [`REG_COUNT-1:0]
);

  logic [`CPU_WIDTH-1:0] rf [`REG_COUNT-1:0];
  logic [`REG_COUNT-1:1] rfwen;

  assign rf[0] = `CPU_WIDTH'b0; // x[0] connect to GND.

  generate                      // x[1]-x[31]:
    for(genvar i=1; i<`REG_COUNT; i=i+1 )begin: regfile
      assign rfwen[i] = i_wen && i_waddr == i;
      stl_reg #(
        .WIDTH     (`CPU_WIDTH   ),
        .RESET_VAL (`CPU_WIDTH'b0)
      ) u_stl_reg (
        .i_clk   (i_clk   ),
        .i_rst_n (i_rst_n ),
        .i_wen   (rfwen[i]),
        .i_din   (i_wdata ),
        .o_dout  (rf[i]   )
      );
    end
  endgenerate

  assign o_rdata1 = rf[i_raddr1];
  assign o_rdata2 = rf[i_raddr2];

  for (genvar i = 0; i < `REG_COUNT; i = i + 1) begin
    assign s_regs[i] = rf[i];
  end

  assign s_a0zero = ~|rf[10]; // if x[10]/a0 is zero, o_a0zero == 1

endmodule
