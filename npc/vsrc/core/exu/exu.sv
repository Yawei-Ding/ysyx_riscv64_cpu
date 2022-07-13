module exu (
  // 1. signal to pipe shake hands:
  input                             i_clk         ,
  input                             i_rst_n       ,
  input                             i_pre_nop     ,
  input                             i_pre_valid   ,   // from pre-stage
  output                            o_pre_ready   ,   //  to  pre-stage
  output                            o_post_valid  ,   //  to  post-stage
  input                             i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input     [`CPU_WIDTH-1:0]        i_idu_imm     ,
  input     [`CPU_WIDTH-1:0]        i_idu_rs1     ,
  input     [`CPU_WIDTH-1:0]        i_idu_rs2     ,
  input     [`REG_ADDRW-1:0]        i_idu_rdid    ,
  input                             i_idu_rdwen   ,
  input     [`EXU_SEL_WIDTH-1:0]    i_idu_exsrc   ,
  input     [`EXU_OPT_WIDTH-1:0]    i_idu_exopt   ,
  input     [2:0]                   i_idu_lsfunc3 ,
  input                             i_idu_lden    ,
  input                             i_idu_sten    ,
  input                             i_idu_ldstbp  ,
  input     [`CPU_WIDTH-1:0]        i_idu_pc      ,
  input     [`CPU_WIDTH-1:0]        s_idu_diffpc  ,
  
  // 3. output comb signal to post stage:
  // 3.1 exu output value:
  output    [`CPU_WIDTH-1:0]        o_exu_res     ,
  // 3.2 for lsu:
  output    [`CPU_WIDTH-1:0]        o_exu_rs2     ,
  output    [2:0]                   o_exu_lsfunc3 ,
  output                            o_exu_lden    ,
  output                            o_exu_sten    ,
  output                            o_exu_ldstbp  ,
  // 3.3 for wbu:
  output    [`REG_ADDRW-1:0]        o_exu_rdid    ,
  output                            o_exu_rdwen   ,
  // 4 for sim:
  output    [`CPU_WIDTH-1:0]        s_exu_diffpc
);

  // 1. shake hands to reg pre stage signals:////////////////////////////////s/////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pipewen;
  assign o_pre_ready =  o_post_valid & i_post_ready | !o_post_valid ;
  assign pipewen = i_pre_valid & o_pre_ready;

  logic  [`CPU_WIDTH-1:0]      idu_imm     ,idu_imm_r     ;
  logic  [`CPU_WIDTH-1:0]      idu_rs1     ,idu_rs1_r     ;
  logic  [`CPU_WIDTH-1:0]      idu_rs2     ,idu_rs2_r     ;
  logic  [`REG_ADDRW-1:0]      idu_rdid    ,idu_rdid_r    ;
  logic                        idu_rdwen   ,idu_rdwen_r   ;
  logic  [`EXU_SEL_WIDTH-1:0]  idu_exsrc   ,idu_exsrc_r   ;
  logic  [`EXU_OPT_WIDTH-1:0]  idu_exopt   ,idu_exopt_r   ;
  logic  [2:0]                 idu_lsfunc3 ,idu_lsfunc3_r ;
  logic                        idu_lden    ,idu_lden_r    ;
  logic                        idu_sten    ,idu_sten_r    ;
  logic                        idu_ldstbp  ,idu_ldstbp_r  ;
  logic  [`CPU_WIDTH-1:0]      idu_pc      ,idu_pc_r      ;
  logic  [`CPU_WIDTH-1:0]      idu_diffpc  ,idu_diffpc_r  ;

  assign idu_imm     = i_pre_nop ? `CPU_WIDTH'b0 : i_idu_imm     ;
  assign idu_rs1     = i_pre_nop ? `CPU_WIDTH'b0 : i_idu_rs1     ;
  assign idu_rs2     = i_pre_nop ? `CPU_WIDTH'b0 : i_idu_rs2     ;
  assign idu_rdid    = i_pre_nop ? `REG_ADDRW'b0 : i_idu_rdid    ;
  assign idu_rdwen   = i_pre_nop ?  1'b0         : i_idu_rdwen   ;
  assign idu_exsrc   = i_pre_nop ? `EXU_SEL_IMM  : i_idu_exsrc   ;
  assign idu_exopt   = i_pre_nop ? `EXU_ADD      : i_idu_exopt   ;
  assign idu_lsfunc3 = i_idu_lsfunc3 ;
  assign idu_lden    = i_pre_nop ?  1'b0         : i_idu_lden    ;
  assign idu_sten    = i_pre_nop ?  1'b0         : i_idu_sten    ;
  assign idu_ldstbp  = i_pre_nop ?  1'b0         : i_idu_ldstbp  ;
  assign idu_pc      = i_idu_pc ;
  assign idu_diffpc  = i_pre_nop ? `CPU_WIDTH'b1 : s_idu_diffpc  ; // use for sim, diffpc == 1 means data nop.

  stl_reg #(
    .WIDTH      (5*`CPU_WIDTH+`REG_ADDRW+7+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pipewen ),
    .i_din      ({idu_imm  , idu_rs1  , idu_rs2  , idu_rdid  , idu_rdwen  , idu_exsrc  , idu_exopt  , idu_lsfunc3  , idu_lden  , idu_sten  , idu_ldstbp  , idu_pc  , idu_diffpc  } ),
    .o_dout     ({idu_imm_r, idu_rs1_r, idu_rs2_r, idu_rdid_r, idu_rdwen_r, idu_exsrc_r, idu_exopt_r, idu_lsfunc3_r, idu_lden_r, idu_sten_r, idu_ldstbp_r, idu_pc_r, idu_diffpc_r} )
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

  exu_logic u_exu_logic(
    .i_pc      (idu_pc_r    ),
    .i_rs1     (idu_rs1_r   ),
    .i_rs2     (idu_rs2_r   ),
    .i_imm     (idu_imm_r   ),
    .i_exsrc   (idu_exsrc_r ),
    .i_exopt   (idu_exopt_r ),
    .o_exu_res (o_exu_res   )
  );

  assign o_exu_rs2     = idu_rs2_r    ;
  assign o_exu_lsfunc3 = idu_lsfunc3_r;
  assign o_exu_lden    = idu_lden_r   ;
  assign o_exu_sten    = idu_sten_r   ;
  assign o_exu_ldstbp  = idu_ldstbp_r ;
  assign o_exu_rdid    = idu_rdid_r   ;
  assign o_exu_rdwen   = idu_rdwen_r  ;
  assign s_exu_diffpc  = idu_diffpc_r ;

endmodule
