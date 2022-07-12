`include "config.sv"
module pipe_ls_wb (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_pre_valid   ,   // from pre-stage
  output                        o_pre_ready   ,   //  to  pre-stage
  output                        o_post_valid  ,   //  to  post-stage
  input                         i_post_ready  ,   // from post-stage

  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]      i_lsu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_lsu_lsres   ,
  input   [`REG_ADDRW-1:0]      i_lsu_rdid    ,
  input                         i_lsu_rdwen   ,
  input                         i_lsu_lden    ,
  input   [`CPU_WIDTH-1:0]      s_lsu_diffpc  ,

  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]      o_wbu_exres   ,
  output  [`CPU_WIDTH-1:0]      o_wbu_lsres   ,
  output  [`REG_ADDRW-1:0]      o_wbu_rdid    ,
  output                        o_wbu_rdwen   ,
  output                        o_wbu_lden    ,
  output  [`CPU_WIDTH-1:0]      s_wbu_diffpc
);

  // 1. pipeline shakehands://///////////////////////////////////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pipewen;
  assign o_pre_ready = o_post_valid & i_post_ready | !o_post_valid;
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

  // 2. transport data from lsu end to wbu start when i_pre_valid & o_pre_ready://////////////
  stl_reg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+2),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pipewen ),
    .i_din      ({i_lsu_exres, i_lsu_lsres, i_lsu_rdid, i_lsu_rdwen, i_lsu_lden, s_lsu_diffpc} ),
    .o_dout     ({o_wbu_exres, o_wbu_lsres, o_wbu_rdid, o_wbu_rdwen, o_wbu_lden, s_wbu_diffpc} )
  );

endmodule
