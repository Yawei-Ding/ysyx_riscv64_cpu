module wbu (
  // 1. signal to pipe shake hands:
  input   logic                   i_clk         ,
  input   logic                   i_rst_n       ,
  input  logic                    i_flush       ,
  input   logic                   i_pre_valid   ,   // from pre-stage
  output  logic                   o_pre_ready   ,   //  to  pre-stage
  output  logic                   o_post_valid  ,   //  to  post-stage
  input   logic                   i_post_ready  ,   // from post-stage
  
  // 2. input comb signal from pre stage:
  input   logic [`CPU_WIDTH-1:0]  i_lsu_exres   ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_lsres   ,
  input   logic                   i_lsu_lden    ,
  input   logic [`REG_ADDRW-1:0]  i_lsu_rdid    ,
  input   logic                   i_lsu_rdwen   ,
  input   logic [`CSR_ADDRW-1:0]  i_lsu_csrdid  ,
  input   logic                   i_lsu_csrdwen ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_csrd    ,
  input   logic [`CPU_WIDTH-1:0]  i_lsu_pc      ,
  input  logic                    i_lsu_ecall   ,
  input  logic                    i_lsu_mret    ,
  input   logic                   i_lsu_nop     ,
  input   logic                   i_iru_intr    ,

  input   logic [`INS_WIDTH-1:0]  s_lsu_ins     ,
  input   logic                   s_lsu_lsclint ,
  input   logic                   s_lsu_device  ,

  // 3. output comb signal to post stage:
  output  logic [`REG_ADDRW-1:0]  o_wbu_rdid    ,
  output  logic                   o_wbu_rdwen   ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_rd      ,

  output  logic [`CSR_ADDRW-1:0]  o_wbu_csrdid  ,
  output  logic                   o_wbu_csrdwen ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_csrd    ,
  
  output  logic                   o_wbu_commit  ,
  output  logic [`CPU_WIDTH-1:0]  o_wbu_pc      ,
  output logic                    o_wbu_ecall   ,
  output logic                    o_wbu_mret    ,
  output  logic                   o_wbu_nop     ,

  // 4 for sim:
  output  logic [`INS_WIDTH-1:0]  s_wbu_ins     ,
  output  logic                   s_wbu_lsclint ,
  output  logic                   s_wbu_device
);

  // 1. shake hands to reg pre stage signals:///////////////////////////////////////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  assign o_pre_ready = o_post_valid & i_post_ready | !o_post_valid;

  wire pre_sh;

  assign pre_sh = i_pre_valid & o_pre_ready;
  assign o_wbu_commit = !i_iru_intr & (o_post_valid & i_post_ready);

  logic [`CPU_WIDTH-1:0]  lsu_exres_r  ;
  logic [`CPU_WIDTH-1:0]  lsu_lsres_r  ;
  logic                   lsu_lden_r   ;
  logic [`REG_ADDRW-1:0]  lsu_rdid_r   ;
  logic                   lsu_rdwen_r  ;
  logic [`CSR_ADDRW-1:0]  lsu_csrdid_r ;
  logic                   lsu_csrdwen_r;
  logic [`CPU_WIDTH-1:0]  lsu_csrd_r   ;
  logic [`CPU_WIDTH-1:0]  lsu_pc_r     ;
  logic [`INS_WIDTH-1:0]  lsu_ins_r    ;
  logic                   lsu_ecall_r  ;
  logic                   lsu_mret_r   ;
  logic                   lsu_nop_r    ;

  stl_reg #(
    .WIDTH      (4*`CPU_WIDTH+`REG_ADDRW+`CSR_ADDRW+8+`INS_WIDTH),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (i_flush | pre_sh ),
    .i_din      (i_flush ? 0 : {i_lsu_exres, i_lsu_lsres, i_lsu_lden, i_lsu_rdid, i_lsu_rdwen, i_lsu_csrdid, i_lsu_csrdwen, i_lsu_csrd, i_lsu_pc, i_lsu_ecall, i_lsu_mret, i_lsu_nop, s_lsu_ins, s_lsu_lsclint, s_lsu_device} ),
    .o_dout     (              {lsu_exres_r, lsu_lsres_r, lsu_lden_r, lsu_rdid_r, lsu_rdwen_r, lsu_csrdid_r, lsu_csrdwen_r, lsu_csrd_r, lsu_pc_r, lsu_ecall_r, lsu_mret_r, lsu_nop_r, lsu_ins_r, s_wbu_lsclint, s_wbu_device} )
  );

  // 2. generate valid signals for post stage://////////////////////////////////////////////////////////////////

  stl_reg #(
    .WIDTH      (1            ), 
    .RESET_VAL  (0            )
  ) postvalid (
  	.i_clk      (i_clk        ), 
    .i_rst_n    (i_rst_n      ), 
    .i_wen      (i_flush | o_pre_ready      ), 
    .i_din      (i_flush ? 1'0: i_pre_valid ), 
    .o_dout     (o_post_valid )
  );

  // 4. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////
  
  assign o_wbu_rdid    = lsu_rdid_r   ;
  assign o_wbu_rdwen   = o_wbu_commit & lsu_rdwen_r;
  assign o_wbu_rd      = lsu_lden_r ? lsu_lsres_r : lsu_exres_r;
  assign o_wbu_csrdid  = lsu_csrdid_r ;
  assign o_wbu_csrdwen = o_wbu_commit & lsu_csrdwen_r;
  assign o_wbu_csrd    = lsu_csrd_r   ;
  assign o_wbu_pc      = lsu_pc_r     ;
  assign o_wbu_ecall   = lsu_ecall_r  ;
  assign o_wbu_mret    = lsu_mret_r   ;
  assign o_wbu_nop     = lsu_nop_r    ;
  assign s_wbu_ins     = lsu_ins_r    ;

endmodule
