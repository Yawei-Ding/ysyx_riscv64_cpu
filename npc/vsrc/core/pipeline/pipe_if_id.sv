`include "config.sv"
module pipe_if_id (
  // 1. control signals:
  input                     i_clk       ,
  input                     i_rst_n     ,
  input                     i_wen       ,
  input                     i_bubble    ,

  // 2. input signals from pre stage:
  input   [`INS_WIDTH-1:0]  i_ifu_ins   ,
  input   [`CPU_WIDTH-1:0]  i_ifu_pc    ,

  // 3. output signals for next stage:
  output  [`INS_WIDTH-1:0]  o_idu_ins   ,
  output  [`CPU_WIDTH-1:0]  o_idu_pc    ,
  output  [`CPU_WIDTH-1:0]  s_idu_diffpc
);

  wire [`CPU_WIDTH-1:0] t_ifu_pc;     // t means temp;
  wire [`INS_WIDTH-1:0] t_ifu_ins; 
  wire [`CPU_WIDTH-1:0] t_ifu_diffpc;

  assign t_ifu_pc     = i_ifu_pc;
  assign t_ifu_ins    = i_bubble ? `INS_WIDTH'h13 : i_ifu_ins;  // 0x13 == ADDI x0,x0,0 == nop.
  assign t_ifu_diffpc = i_bubble ? `CPU_WIDTH'b0  : i_ifu_pc;   // use for sim, branch bubble diffpc == 0;

  stl_reg #(
    .WIDTH      (2*`CPU_WIDTH+`INS_WIDTH),
    .RESET_VAL  (0                    )
  ) if_id_reg(
  	.i_clk      (i_clk                ),
    .i_rst_n    (i_rst_n              ),
    .i_wen      (i_wen                ),
    .i_din      ({t_ifu_ins,t_ifu_pc,t_ifu_diffpc}),
    .o_dout     ({o_idu_ins,o_idu_pc,s_idu_diffpc})
  );
  
endmodule
