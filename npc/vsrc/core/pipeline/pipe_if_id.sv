`include "config.sv"
module pipe_if_id (
  // 1. control signals:
  input                     i_clk       ,
  input                     i_rst_n     ,
  input                     i_nop       ,
  input                     i_stall     ,
  input                     i_pre_valid ,   // from pre-stage
  output                    o_pre_ready ,   //  to  pre-stage
  output                    o_post_valid,   //  to  post-stage
  input                     i_post_ready,   // from post-stage

  // 2. input signals from pre stage:
  input   [`INS_WIDTH-1:0]  i_ifu_ins   ,
  input   [`CPU_WIDTH-1:0]  i_ifu_pc    ,

  // 3. output signals for next stage:
  output  [`INS_WIDTH-1:0]  o_idu_ins   ,
  output  [`CPU_WIDTH-1:0]  o_idu_pc    ,
  output  [`CPU_WIDTH-1:0]  s_idu_diffpc
);

  // 1. pipeline shakehands://///////////////////////////////////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pipewen;
  assign o_pre_ready = (!i_stall) & ( o_post_valid & i_post_ready | !o_post_valid );
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

  // 2. transport data from ifu end to idu start when i_pre_valid & o_pre_ready://////////////
  wire [`CPU_WIDTH-1:0] t_ifu_pc;     // t means temp;
  wire [`INS_WIDTH-1:0] t_ifu_ins; 
  wire [`CPU_WIDTH-1:0] t_ifu_diffpc;

  assign t_ifu_pc     = i_ifu_pc;
  assign t_ifu_ins    = i_nop ? `INS_WIDTH'h13 : i_ifu_ins;  // 0x13 == ADDI x0,x0,0 == nop.
  assign t_ifu_diffpc = i_nop ? `CPU_WIDTH'b0  : i_ifu_pc;   // use for sim, branch bubble diffpc == 0;

  stl_reg #(
    .WIDTH      (2*`CPU_WIDTH+`INS_WIDTH),
    .RESET_VAL  (0                      )
  ) regs(
  	.i_clk      (i_clk                  ),
    .i_rst_n    (i_rst_n                ),
    .i_wen      (pipewen                ),
    .i_din      ({t_ifu_ins,t_ifu_pc,t_ifu_diffpc}),
    .o_dout     ({o_idu_ins,o_idu_pc,s_idu_diffpc})
  );
  
endmodule
