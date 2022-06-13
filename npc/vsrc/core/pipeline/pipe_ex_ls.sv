`include "config.sv"
module pipe_ex_ls (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,

  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]      i_exu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_exu_rs2     ,
  input   [`REG_ADDRW-1:0]      i_exu_rdid    ,
  input                         i_exu_rdwen   ,
  input   [2:0]                 i_exu_func3   ,
  input                         i_exu_lden    ,
  input                         i_exu_sten    ,
  input   [`CPU_WIDTH-1:0]      s_exu_diffpc  ,

  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]      o_lsu_exres   ,
  output  [`CPU_WIDTH-1:0]      o_lsu_rs2     ,
  output  [`REG_ADDRW-1:0]      o_lsu_rdid    ,
  output                        o_lsu_rdwen   ,
  output  [2:0]                 o_lsu_func3   ,
  output                        o_lsu_lden    ,
  output                        o_lsu_sten    ,
  output  [`CPU_WIDTH-1:0]      s_lsu_diffpc
);

  stl_reg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+6),
    .RESET_VAL  (0       )
  ) if_id_reg(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (1       ),
    .i_din      ({i_exu_exres, i_exu_rs2, i_exu_rdid, i_exu_rdwen, i_exu_func3, i_exu_lden, i_exu_sten, s_exu_diffpc} ),
    .o_dout     ({o_lsu_exres, o_lsu_rs2, o_lsu_rdid, o_lsu_rdwen, o_lsu_func3, o_lsu_lden, o_lsu_sten, s_lsu_diffpc} )
  );

endmodule
