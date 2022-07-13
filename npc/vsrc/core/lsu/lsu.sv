module lsu (
  // 1. signal to pipe shake hands:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_pre_valid   ,   // from pre-stage
  output                        o_pre_ready   ,   //  to  pre-stage
  output                        o_post_valid  ,   //  to  post-stage
  input                         i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input   [`CPU_WIDTH-1:0]      i_exu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_exu_rs2     ,
  input   [`REG_ADDRW-1:0]      i_exu_rdid    ,
  input                         i_exu_rdwen   ,
  input   [2:0]                 i_exu_lsfunc3 ,
  input                         i_exu_lden    ,
  input                         i_exu_sten    ,
  input   [`CPU_WIDTH-1:0]      s_exu_diffpc  ,
  
  // 3. output comb signal to post stage:
  output  [`CPU_WIDTH-1:0]      o_lsu_lsres   ,
  output  [`CPU_WIDTH-1:0]      o_lsu_exres   ,
  output                        o_lsu_lden    ,
  output  [`REG_ADDRW-1:0]      o_lsu_rdid    ,
  output                        o_lsu_rdwen   ,
  // 4 for sim:
  output  [`CPU_WIDTH-1:0]      s_lsu_diffpc
);

  // 1. shake hands to reg pre stage signals:////////////////////////////////s/////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pipewen;
  assign o_pre_ready =  o_post_valid & i_post_ready | !o_post_valid ;
  assign pipewen = i_pre_valid & o_pre_ready;

  logic  [`CPU_WIDTH-1:0]  exu_exres_r    ;
  logic  [`CPU_WIDTH-1:0]  exu_rs2_r      ;
  logic  [`REG_ADDRW-1:0]  exu_rdid_r     ;
  logic                    exu_rdwen_r    ;
  logic  [2:0]             exu_lsfunc3_r  ;
  logic                    exu_lden_r     ;
  logic                    exu_sten_r     ;
  logic  [`CPU_WIDTH-1:0]  exu_diffpc_r   ;

  stl_reg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+6),
    .RESET_VAL  (0       )
  ) prereg (
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pipewen ),
    .i_din      ({i_exu_exres, i_exu_rs2, i_exu_rdid, i_exu_rdwen, i_exu_lsfunc3, i_exu_lden, i_exu_sten, s_exu_diffpc} ),
    .o_dout     ({exu_exres_r, exu_rs2_r, exu_rdid_r, exu_rdwen_r, exu_lsfunc3_r, exu_lden_r, exu_sten_r, exu_diffpc_r} )
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
  
  lsu_logic u_lsu_logic(
    .i_clk     (i_clk         ),
    .i_lsfunc3 (exu_lsfunc3_r ),
    .i_lden    (exu_lden_r    ),
    .i_sten    (exu_sten_r    ),
    .i_addr    (exu_exres_r   ),
    .i_regst   (exu_rs2_r     ),
    .o_regld   (o_lsu_lsres   )
  );

  assign  o_lsu_exres  = exu_exres_r  ;
  assign  o_lsu_lden   = exu_lden_r   ;
  assign  o_lsu_rdid   = exu_rdid_r   ;
  assign  o_lsu_rdwen  = exu_rdwen_r  ;
  assign  s_lsu_diffpc = exu_diffpc_r ;

endmodule
