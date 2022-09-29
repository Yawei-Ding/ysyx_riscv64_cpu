`include "defines.sv"
module bru (
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_idu_valid   , // use for jalr, to fix bug with: jalr x[n],x[n],imm
  input     [`REG_ADDRW-1:0]    i_idu_rs1id   , // use for jalr, to fix bug with: jalr x[n],x[n],imm
  input     [`REG_ADDRW-1:0]    i_exu_rdid    , // use for jalr, to fix bug with: jalr x[n],x[n],imm
  input                         i_jal         ,
  input                         i_jalr        ,
  input                         i_brch        ,
  input     [2:0]               i_bfun3       ,
  input     [`CPU_WIDTH-1:0]    i_rs1         ,
  input     [`CPU_WIDTH-1:0]    i_rs2         ,
  input     [`CPU_WIDTH-1:0]    i_imm         ,
  input     [`CPU_WIDTH-1:0]    i_ifupc       ,
  input     [`CPU_WIDTH-1:0]    i_idupc       ,
  input                         i_iru_jump    ,
  input     [`CPU_WIDTH-1:0]    i_iru_pc      ,
  input                         i_fence_jump  ,
  input     [`CPU_WIDTH-1:0]    i_fence_pc    ,
  output    [`CPU_WIDTH-1:0]    o_next_pc     ,
  output                        o_ifid_nop
);

  // 0. use reg to save rs1 for alr x[n],x[n],imm. means rs1id == rdid:
  logic [`CPU_WIDTH-1:0] i_rs1_r, rs1;

  wire jalr_rs1id_eq_rdid = i_jalr & (i_exu_rdid == i_idu_rs1id);

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) jalr_save (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (i_idu_valid & jalr_rs1id_eq_rdid ),
    .i_din    (i_rs1        ),
    .o_dout   (i_rs1_r      )
  );

  assign rs1 = (!i_idu_valid & jalr_rs1id_eq_rdid) ? i_rs1_r : i_rs1;

  // 1. generate bjump: ///////////////////////////////////////////////
  logic bjump, supersub_resbit;
  logic [`CPU_WIDTH-1:0] sub_res, no_use;

  assign sub_res = i_rs1 - i_rs2;
  assign {supersub_resbit, no_use} = {1'b0,i_rs1} - {1'b0,i_rs2};

  stl_mux_default #(6,3,1) mux_branch (bjump, i_bfun3, 1'b0, {
    `FUNC3_BEQ ,   ~(|sub_res)           ,
    `FUNC3_BNE ,    (|sub_res)           ,
    `FUNC3_BLT ,    sub_res[`CPU_WIDTH-1],
    `FUNC3_BGE ,   ~sub_res[`CPU_WIDTH-1],
    `FUNC3_BLTU,    supersub_resbit      ,
    `FUNC3_BGEU,   ~supersub_resbit
  });

  wire jump = (i_brch ? bjump : 1'b0) ||  i_jal || i_jalr;

  // 2. set next_pc:///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] seq_pc, jump_pc;

  assign seq_pc  = i_ifupc + 4;
  assign jump_pc = i_jalr ? (rs1 + i_imm) : (i_idupc + i_imm);  //means 1 for jalr , 0 for jal || bjump.
  assign o_next_pc = i_fence_jump ? i_fence_pc : (i_iru_jump ? i_iru_pc : (jump ? jump_pc : seq_pc));
  assign o_ifid_nop = jump;

  // 3. update pc in ifu - pipe_pc_if, use next_pc to update pc.

endmodule
