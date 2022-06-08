`include "config.sv"
module pipe_ex_ls (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_pause       ,
  input                         i_exu_valid   ,
  input                         i_lsu_ready   ,

  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]      i_exu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_exu_rs2     ,
  input   [`REG_ADDRW-1:0]      i_exu_rdid    ,
  input                         i_exu_rdwen   ,
  input   [`LSU_OPT_WIDTH-1:0]  i_exu_lsopt   ,

  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]      o_lsu_exres   ,
  output  [`CPU_WIDTH-1:0]      o_lsu_rs2     ,
  output  [`REG_ADDRW-1:0]      o_lsu_rdid    ,
  output                        o_lsu_rdwen   ,
  output  [`LSU_OPT_WIDTH-1:0]  o_lsu_lsopt   
);

  wire wen = !i_pause && i_exu_valid && i_lsu_ready;

  stdreg #(
    .WIDTH      (2*`CPU_WIDTH+`REG_ADDRW+1+`LSU_OPT_WIDTH ),
    .RESET_VAL  (0       )
  ) if_id_reg(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (wen     ),
    .i_din      ({i_exu_exres, i_exu_rs2, i_exu_rdid, i_exu_rdwen, i_exu_lsopt} ),
    .o_dout     ({o_lsu_exres, o_lsu_rs2, o_lsu_rdid, o_lsu_rdwen, o_lsu_lsopt} )
  );

endmodule
