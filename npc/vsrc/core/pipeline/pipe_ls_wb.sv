`include "config.sv"
module pipe_ls_wb (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_pause       ,
  input                         i_lsu_valid   ,
  input                         i_wbu_ready   ,

  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]      i_lsu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_lsu_lsres   ,
  input   [`REG_ADDRW-1:0]      i_lsu_rdid    ,
  input                         i_lsu_rdwen   ,
  input                         i_lsu_ldflag  ,

  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]      o_wbu_exres   ,
  output  [`CPU_WIDTH-1:0]      o_wbu_lsres   ,
  output  [`REG_ADDRW-1:0]      o_wbu_rdid    ,
  output                        o_wbu_rdwen   ,
  output                        o_wbu_ldflag  
);

  wire wen = !i_pause && i_lsu_valid && i_wbu_ready;

  stdreg #(
    .WIDTH      (2*`CPU_WIDTH+`REG_ADDRW+2),
    .RESET_VAL  (0       )
  ) if_id_reg(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (wen     ),
    .i_din      ({i_lsu_exres, i_lsu_lsres, i_lsu_rdid, i_lsu_rdwen, i_lsu_ldflag} ),
    .o_dout     ({o_wbu_exres, o_wbu_lsres, o_wbu_rdid, o_wbu_rdwen, o_wbu_ldflag} )
  );

endmodule
