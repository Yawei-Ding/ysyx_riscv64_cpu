`include "config.sv"
module bru (
  input                         i_jal       ,
  input                         i_jalr      ,
  input                         i_brch      ,
  input        [2:0]            i_bfun3     ,
  input        [`CPU_WIDTH-1:0] i_rs1       ,
  input        [`CPU_WIDTH-1:0] i_rs2       ,
  input        [`CPU_WIDTH-1:0] i_imm       ,
  input        [`CPU_WIDTH-1:0] i_ifupc     ,
  input        [`CPU_WIDTH-1:0] i_idupc     ,
  output       [`CPU_WIDTH-1:0] o_next_pc   ,
  output                        o_ifid_nop
);

  // 1. generate bjump: ///////////////////////////////////////////////
  logic bjump;
  logic supersub_resbit;
  logic [`CPU_WIDTH-1:0] sub_res;

  assign sub_res = i_rs1 - i_rs2;
  assign supersub_resbit = {{1'b0,i_rs1} - {1'b0,i_rs2}}[`CPU_WIDTH];

  stl_mux_default #(6,3,1) mux_branch (bjump, i_bfun3, 0, {
    `FUNC3_BEQ ,   ~(|sub_res)           ,
    `FUNC3_BNE ,    (|sub_res)           ,
    `FUNC3_BLT ,    sub_res[`CPU_WIDTH-1],
    `FUNC3_BGE ,   ~sub_res[`CPU_WIDTH-1],
    `FUNC3_BLTU,    supersub_resbit      ,
    `FUNC3_BGEU,   ~supersub_resbit
  });

  assign o_ifid_nop = (i_brch ? bjump : 1'b0) ||  i_jal || i_jalr;

  // 2. set next_pc:///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] seq_pc, jump_pc;

  assign seq_pc  = i_ifupc + 4;
  assign jump_pc = i_jalr ? (i_rs1 + i_imm) : (i_idupc + i_imm);  //means 1 for jalr , 0 for jal || bjump.
  assign o_next_pc = o_ifid_nop ? jump_pc : seq_pc;

  // 3. update pc in ifu - pipe_pc_if, use next_pc to update pc.

endmodule
