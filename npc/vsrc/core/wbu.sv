module wbu (
  // 1. signal to pipe shake hands:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_pre_valid   ,   // from pre-stage
  output                        o_pre_ready   ,   //  to  pre-stage

  // 2. input comb signal from pre stage:
  input   [`CPU_WIDTH-1:0]      i_lsu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_lsu_lsres   ,
  input   [`REG_ADDRW-1:0]      i_lsu_rdid    ,
  input                         i_lsu_rdwen   ,
  input                         i_lsu_lden    ,
  input   [`CPU_WIDTH-1:0]      s_lsu_diffpc  ,
  input   [`INS_WIDTH-1:0]      s_lsu_ins     ,

  // 3. output comb signal to post stage:
  output                        o_wbu_rdwen   ,
  output  [`CPU_WIDTH-1:0]      o_wbu_rd      ,
  output  [`REG_ADDRW-1:0]      o_wbu_rdid    ,
  // 4 for sim:
  output  [`CPU_WIDTH-1:0]      s_wbu_diffpc  ,
  output  [`INS_WIDTH-1:0]      s_wbu_ins
);

  // 1. shake hands to reg pre stage signals:////////////////////////////////s/////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pre_sh, o_post_valid, i_post_ready;
  assign o_pre_ready = o_post_valid & i_post_ready | !o_post_valid;
  assign pre_sh = i_pre_valid & o_pre_ready;

  logic [`CPU_WIDTH-1:0]  lsu_exres_r  ;
  logic [`CPU_WIDTH-1:0]  lsu_lsres_r  ;
  logic [`REG_ADDRW-1:0]  lsu_rdid_r   ;
  logic                   lsu_rdwen_r  ;
  logic                   lsu_lden_r   ;
  logic [`CPU_WIDTH-1:0]  lsu_diffpc_r ;
  logic [`INS_WIDTH-1:0]  lsu_ins_r    ;

  stl_reg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+2+`INS_WIDTH),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pre_sh ),
    .i_din      ({i_lsu_exres, i_lsu_lsres, i_lsu_rdid, i_lsu_rdwen, i_lsu_lden, s_lsu_diffpc, s_lsu_ins} ),
    .o_dout     ({lsu_exres_r, lsu_lsres_r, lsu_rdid_r, lsu_rdwen_r, lsu_lden_r, lsu_diffpc_r, lsu_ins_r} )
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
  
  assign i_post_ready = 1;  // post stage(regfile) always be ready to receive data.
  assign o_wbu_rdwen = o_post_valid & i_post_ready & lsu_rdwen_r;

  // 3. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////

  assign o_wbu_rd     = lsu_lden_r ? lsu_lsres_r : lsu_exres_r;
  assign o_wbu_rdid   = lsu_rdid_r  ;
  assign s_wbu_diffpc = lsu_diffpc_r;
  assign s_wbu_ins    = lsu_ins_r   ;

endmodule
