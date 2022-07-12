`include "config.sv"
module pipe_id_ex (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_nop         ,
  input                         i_pre_valid   ,   // from pre-stage
  output                        o_pre_ready   ,   //  to  pre-stage
  output                        o_post_valid  ,   //  to  post-stage
  input                         i_post_ready  ,   // from post-stage

  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]      i_idu_imm     ,
  input   [`CPU_WIDTH-1:0]      i_idu_rs1     ,
  input   [`CPU_WIDTH-1:0]      i_idu_rs2     ,
  input   [`REG_ADDRW-1:0]      i_idu_rdid    ,
  input                         i_idu_rdwen   ,
  input   [`EXU_SEL_WIDTH-1:0]  i_idu_src_sel ,
  input   [`EXU_OPT_WIDTH-1:0]  i_idu_exopt   ,
  input   [2:0]                 i_idu_func3   ,
  input                         i_idu_lden    ,
  input                         i_idu_sten    ,
  input                         i_idu_ldstbp  ,
  input   [`CPU_WIDTH-1:0]      i_idu_pc      ,
  input   [`CPU_WIDTH-1:0]      s_idu_diffpc  ,

  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]      o_exu_imm     ,
  output  [`CPU_WIDTH-1:0]      o_exu_rs1     ,
  output  [`CPU_WIDTH-1:0]      o_exu_rs2     ,
  output  [`REG_ADDRW-1:0]      o_exu_rdid    ,
  output                        o_exu_rdwen   ,
  output  [`EXU_SEL_WIDTH-1:0]  o_exu_src_sel ,
  output  [`EXU_OPT_WIDTH-1:0]  o_exu_exopt   ,
  output  [2:0]                 o_exu_func3   ,
  output                        o_exu_lden    ,
  output                        o_exu_sten    ,
  output                        o_exu_ldstbp  ,
  output  [`CPU_WIDTH-1:0]      o_exu_pc      , 
  output  [`CPU_WIDTH-1:0]      s_exu_diffpc
);

  // 1. pipeline shakehands://///////////////////////////////////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready


  wire pipewen;
  assign o_pre_ready =  o_post_valid & i_post_ready | !o_post_valid ;
  assign pipewen = i_pre_valid & o_pre_ready;

  stl_reg #(
    .WIDTH      (1            ), 
    .RESET_VAL  (0            )
  ) pipe(
  	.i_clk      (i_clk        ), 
    .i_rst_n    (i_rst_n      ), 
    .i_wen      (o_pre_ready  ), 
    .i_din      (i_pre_valid  ), 
    .o_dout     (o_post_valid )
  );
  
  // 2. transport data from idu end to exu start when i_pre_valid & o_pre_ready://////////////
  logic  [`CPU_WIDTH-1:0]      t_idu_imm     ;
  logic  [`CPU_WIDTH-1:0]      t_idu_rs1     ;
  logic  [`CPU_WIDTH-1:0]      t_idu_rs2     ;
  logic  [`REG_ADDRW-1:0]      t_idu_rdid    ;
  logic                        t_idu_rdwen   ;
  logic  [`EXU_SEL_WIDTH-1:0]  t_idu_src_sel ;
  logic  [`EXU_OPT_WIDTH-1:0]  t_idu_exopt   ;
  logic  [2:0]                 t_idu_func3   ;
  logic                        t_idu_lden    ;
  logic                        t_idu_sten    ;
  logic                        t_idu_ldstbp  ;
  logic  [`CPU_WIDTH-1:0]      t_idu_pc      ;
  logic  [`CPU_WIDTH-1:0]      t_idu_diffpc  ;

  assign t_idu_imm     = i_nop ? `CPU_WIDTH'b0 : i_idu_imm     ;
  assign t_idu_rs1     = i_nop ? `CPU_WIDTH'b0 : i_idu_rs1     ;
  assign t_idu_rs2     = i_nop ? `CPU_WIDTH'b0 : i_idu_rs2     ;
  assign t_idu_rdid    = i_nop ? `REG_ADDRW'b0 : i_idu_rdid    ;
  assign t_idu_rdwen   = i_nop ?  1'b0         : i_idu_rdwen   ;
  assign t_idu_src_sel = i_nop ? `EXU_SEL_IMM  : i_idu_src_sel ;
  assign t_idu_exopt   = i_nop ? `EXU_ADD      : i_idu_exopt   ;
  assign t_idu_func3   = i_idu_func3 ;
  assign t_idu_lden    = i_nop ?  1'b0         : i_idu_lden    ;
  assign t_idu_sten    = i_nop ?  1'b0         : i_idu_sten    ;
  assign t_idu_ldstbp  = i_nop ?  1'b0         : i_idu_ldstbp  ;
  assign t_idu_pc      = i_idu_pc ;
  assign t_idu_diffpc  = i_nop ? `CPU_WIDTH'b1 : s_idu_diffpc  ; // use for sim, diffpc == 1 means data nop.

  stl_reg #(
    .WIDTH      (5*`CPU_WIDTH+`REG_ADDRW+7+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pipewen ),
    .i_din      ({t_idu_imm, t_idu_rs1, t_idu_rs2, t_idu_rdid, t_idu_rdwen, t_idu_src_sel, t_idu_exopt, t_idu_func3, t_idu_lden, t_idu_sten, t_idu_ldstbp, t_idu_pc, t_idu_diffpc} ),
    .o_dout     ({o_exu_imm, o_exu_rs1, o_exu_rs2, o_exu_rdid, o_exu_rdwen, o_exu_src_sel, o_exu_exopt, o_exu_func3, o_exu_lden, o_exu_sten, o_exu_ldstbp, o_exu_pc, s_exu_diffpc} )
  );

endmodule
