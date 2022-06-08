`include "config.sv"
module pipe_id_ex (
  // 1. control signals:
  input                         i_clk         ,
  input                         i_rst_n       ,
  input                         i_pause       ,
  input                         i_idu_valid   ,
  input                         i_exu_ready   ,
  
  // 2. input signals from pre stage:
  input   [`CPU_WIDTH-1:0]      i_idu_pc      ,
  input   [`CPU_WIDTH-1:0]      i_idu_imm     ,
  input   [`CPU_WIDTH-1:0]      i_idu_rs1     ,
  input   [`CPU_WIDTH-1:0]      i_idu_rs2     ,
  input   [`REG_ADDRW-1:0]      i_idu_rdid    ,
  input                         i_idu_rdwen   ,
  input   [`EXU_SEL_WIDTH-1:0]  i_idu_src_sel ,
  input   [`EXU_OPT_WIDTH-1:0]  i_idu_exopt   ,
  input   [`LSU_OPT_WIDTH-1:0]  i_idu_lsopt   ,


  // 3. output signals for next stage:
  output  [`CPU_WIDTH-1:0]      o_exu_pc      , 
  output  [`CPU_WIDTH-1:0]      o_exu_imm     ,
  output  [`CPU_WIDTH-1:0]      o_exu_rs1     ,
  output  [`CPU_WIDTH-1:0]      o_exu_rs2     ,
  output  [`REG_ADDRW-1:0]      o_exu_rdid    ,
  output                        o_exu_rdwen   ,
  output  [`EXU_SEL_WIDTH-1:0]  o_exu_src_sel ,
  output  [`EXU_OPT_WIDTH-1:0]  o_exu_exopt   ,
  output  [`LSU_OPT_WIDTH-1:0]  o_exu_lsopt
);

  wire wen = !i_pause && i_idu_valid && i_exu_ready;

  stdreg #(
    .WIDTH      (4*`CPU_WIDTH+`REG_ADDRW+1+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH+`LSU_OPT_WIDTH ),
    .RESET_VAL  (0       )
  ) if_id_reg(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (wen     ),
    .i_din      ({i_idu_pc, i_idu_imm, i_idu_rs1, i_idu_rs2, i_idu_rdid, i_idu_rdwen, i_idu_src_sel, i_idu_exopt, i_idu_lsopt} ),
    .o_dout     ({o_exu_pc, o_exu_imm, o_exu_rs1, o_exu_rs2, o_exu_rdid, o_exu_rdwen, o_exu_src_sel, o_exu_exopt, o_exu_lsopt} )
  );

endmodule
