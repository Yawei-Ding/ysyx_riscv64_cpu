module idu (
  // 1. signal to pipe shake hands:
  input                             i_clk         ,
  input                             i_rst_n       ,
  input                             i_pre_nop     ,
  input                             i_pre_stall   ,
  input                             i_pre_valid   ,   // from pre-stage
  output                            o_pre_ready   ,   //  to  pre-stage
  output                            o_post_valid  ,   //  to  post-stage
  input                             i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input        [`INS_WIDTH-1:0]     i_ifu_ins     ,
  input        [`CPU_WIDTH-1:0]     i_ifu_pc      ,

  // 3. output comb signal to post stage:
  // 3.1 for bypass to get reg value.
  output logic [`REG_ADDRW-1:0]     o_idu_rs1id   ,
  output logic [`REG_ADDRW-1:0]     o_idu_rs2id   ,
  // 3.2 for wbu:
  output logic [`REG_ADDRW-1:0]     o_idu_rdid    ,
  output logic                      o_idu_rdwen   ,
  // 3.3 for exu:
  output logic [`CPU_WIDTH-1:0]     o_idu_imm     ,
  output logic [`EXU_SEL_WIDTH-1:0] o_idu_exsrc   ,
  output logic [`EXU_OPT_WIDTH-1:0] o_idu_exopt   ,
  // 3.4 for lsu:
  output logic [2:0]                o_idu_lsfunc3 ,
  output logic                      o_idu_lden    ,
  output logic                      o_idu_sten    ,
  // 3.5 for bru:
  output logic                      o_idu_jal     ,
  output logic                      o_idu_jalr    ,
  output logic                      o_idu_brch    ,
  output logic [2:0]                o_idu_bfun3   ,
  // 3.6 for next stage to pipe:
  output logic [`CPU_WIDTH-1:0]     o_idu_pc      ,
  // 4 for sim:
  output logic [`CPU_WIDTH-1:0]     s_idu_diffpc  ,
  output logic [2:0]                s_idu_iderr     // bit0:opc_err, bit1:func3_err, bit2:func7_err
);

  // 1. shake hands to reg pre stage signals://///////////////////////////////////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pre_sh;
  assign o_pre_ready =  o_post_valid & i_post_ready & (!i_pre_stall) | !o_post_valid ;
  assign pre_sh = i_pre_valid & o_pre_ready;

  logic [`CPU_WIDTH-1:0] ifu_pc    ,ifu_pc_r;
  logic [`INS_WIDTH-1:0] ifu_ins   ,ifu_ins_r;
  logic [`CPU_WIDTH-1:0] ifu_diffpc,ifu_diffpc_r;

  assign ifu_pc      = i_ifu_pc;
  assign ifu_ins    = i_pre_nop ? `INS_WIDTH'h13 : i_ifu_ins;  // 0x13 == ADDI x0,x0,0 == nop.
  assign ifu_diffpc = i_pre_nop ? `CPU_WIDTH'b0  : i_ifu_pc;   // use for sim, branch nop diffpc == 0

  stl_reg #(
    .WIDTH      (2*`CPU_WIDTH+`INS_WIDTH),
    .RESET_VAL  (0                      )
  ) prereg (
  	.i_clk      (i_clk                  ),
    .i_rst_n    (i_rst_n                ),
    .i_wen      (pre_sh                ),
    .i_din      ({ifu_ins  , ifu_pc  , ifu_diffpc  }),
    .o_dout     ({ifu_ins_r, ifu_pc_r, ifu_diffpc_r})
  );

  // 2. generate valid signals for post stage://////////////////////////////////////////////////////////////////

  stl_reg #(
    .WIDTH      (1            ), 
    .RESET_VAL  (0            )
  ) postvalid (
  	.i_clk      (i_clk        ), 
    .i_rst_n    (i_rst_n      ), 
    .i_wen      (o_pre_ready  ), 
    .i_din      (i_pre_valid  ), 
    .o_dout     (o_post_valid )
  );

  // 3. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////

  idu_logic u_idu_logic(
    .i_ins       (ifu_ins_r     ),
    .o_rs1id     (o_idu_rs1id   ),
    .o_rs2id     (o_idu_rs2id   ),
    .o_rdid      (o_idu_rdid    ),
    .o_rdwen     (o_idu_rdwen   ),
    .o_imm       (o_idu_imm     ),
    .o_src_sel   (o_idu_exsrc   ),
    .o_exopt     (o_idu_exopt   ),
    .o_lsu_func3 (o_idu_lsfunc3 ),
    .o_lsu_lden  (o_idu_lden    ),
    .o_lsu_sten  (o_idu_sten    ),
    .o_jal       (o_idu_jal     ),
    .o_jalr      (o_idu_jalr    ),
    .o_brch      (o_idu_brch    ),
    .o_bfun3     (o_idu_bfun3   ),
    .s_id_err    (s_idu_iderr   )
  );

  assign o_idu_pc     = ifu_pc_r    ;
  assign s_idu_diffpc = ifu_diffpc_r;

endmodule
