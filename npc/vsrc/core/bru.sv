`include "config.sv"
module bru (
  input                         i_clk  ,
  input                         i_rst_n,
  input                         i_pcwen,
  input                         i_jal  ,
  input                         i_jalr ,
  input                         i_brch ,
  input        [2:0]            i_bfun3,
  input        [`CPU_WIDTH-1:0] i_rs1  ,
  input        [`CPU_WIDTH-1:0] i_rs2  ,
  input        [`CPU_WIDTH-1:0] i_imm  ,
  input        [`CPU_WIDTH-1:0] i_prepc,
  output wire  [`CPU_WIDTH-1:0] o_pc   ,
  output                        o_ifid_bubble
);

  // 1. generate branch: ///////////////////////////////////////////////
  logic branch,jump;
  logic supersub_resbit;
  logic [`CPU_WIDTH-1:0] sub_res;

  assign sub_res = i_rs1 - i_rs2;
  assign supersub_resbit = {{1'b0,i_rs1} - {1'b0,i_rs2}}[`CPU_WIDTH];

  stl_mux_default #(6,3,1) mux_branch (branch, i_bfun3, 0, {
    `FUNC3_BEQ ,   ~(|sub_res)           ,
    `FUNC3_BNE ,    (|sub_res)           ,
    `FUNC3_BLT ,    sub_res[`CPU_WIDTH-1],
    `FUNC3_BGE ,   ~sub_res[`CPU_WIDTH-1],
    `FUNC3_BLTU,    supersub_resbit      ,
    `FUNC3_BGEU,   ~supersub_resbit
  });

  assign jump = (i_brch ? branch : 1'b0) ||  i_jal || i_jalr;
  assign o_ifid_bubble = jump;

  // 2. set next_pc:///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] seq_pc, jump_pc, next_pc;

  assign seq_pc  = o_pc + 4;
  assign jump_pc = i_jalr ? (i_rs1 + i_imm) : (i_prepc + i_imm);  //means 1 for jalr , 0 for jal || branch.
  assign next_pc = jump ? jump_pc : seq_pc;

  // 2. update pc:///////////////////////////////////////////////
  stl_reg #(
    .WIDTH     (`CPU_WIDTH          ),
    .RESET_VAL (`CPU_WIDTH'h80000000)
  )u_stl_reg(
    .i_clk   (i_clk   ),
    .i_rst_n (i_rst_n ),
    .i_wen   (i_pcwen ),
    .i_din   (next_pc ),
    .o_dout  (o_pc    )
  );

endmodule
