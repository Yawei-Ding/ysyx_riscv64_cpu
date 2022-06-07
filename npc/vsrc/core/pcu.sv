`include "config.sv"
module pcu (
    input                         i_clk  ,
    input                         i_rst_n,
    input                         i_brch ,
    input                         i_jal  ,
    input                         i_jalr ,
    input                         i_zero ,
    input        [`CPU_WIDTH-1:0] i_rs1  ,
    input        [`CPU_WIDTH-1:0] i_imm  ,
    output wire  [`CPU_WIDTH-1:0] o_pc
);

  wire [`CPU_WIDTH-1:0] pc_next;

  assign pc_next = (i_brch && ~i_zero || i_jal) ? (o_pc + i_imm) : (i_jalr ? (i_rs1 + i_imm) : (o_pc + 4) );

  stdreg #(
    .WIDTH     (`CPU_WIDTH  ),
    .RESET_VAL (64'h80000000)
  )u_stdreg(
    .i_clk   (i_clk   ),
    .i_rst_n (i_rst_n ),
    .i_wen   (1       ),
    .i_din   (pc_next ),
    .o_dout  (o_pc    )
  );

endmodule
