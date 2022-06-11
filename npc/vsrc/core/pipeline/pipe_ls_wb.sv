`include "config.sv"
module pipe_ls_wb (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,

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

  stdreg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+2),
    .RESET_VAL  (0       )
  ) if_id_reg(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (1       ),
    .i_din      ({i_lsu_exres, i_lsu_lsres, i_lsu_rdid, i_lsu_rdwen, i_lsu_lden, s_lsu_diffpc} ),
    .o_dout     ({o_wbu_exres, o_wbu_lsres, o_wbu_rdid, o_wbu_rdwen, o_wbu_lden, s_wbu_diffpc} )
  );

endmodule
