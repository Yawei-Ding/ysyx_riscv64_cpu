`include "config.sv"
module pipe_if_id (
  // 1. control signals:
  input                     i_clk       ,
  input                     i_rst_n     ,
  input                     i_pause     ,
  input                     i_ifu_valid ,
  input                     i_idu_ready ,

  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]  i_ifu_pc    ,
  input   [`INS_WIDTH-1:0]  i_ifu_ins   ,
  
  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]  o_idu_pc    ,
  output  [`INS_WIDTH-1:0]  o_idu_ins  
);
  
  wire wen = !i_pause && i_ifu_valid && i_idu_ready;

  stdreg #(
    .WIDTH      (`CPU_WIDTH+`INS_WIDTH),
    .RESET_VAL  (0                    )
  ) if_id_reg(
  	.i_clk      (i_clk                ),
    .i_rst_n    (i_rst_n              ),
    .i_wen      (wen                  ),
    .i_din      ({i_ifu_pc, i_ifu_ins}),
    .o_dout     ({o_idu_pc, o_idu_ins})
  );
  
endmodule
