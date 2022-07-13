`include "config.sv"
module bypass (
  input                            i_clk         ,

  // 1. from exu/lsu/wbu to generate rs1/rs2 for idu:
  // from idu:
  input         [`REG_ADDRW-1:0]   i_idu_rs1id   ,
  input         [`REG_ADDRW-1:0]   i_idu_rs2id   ,
  input                            i_idu_sten    ,
  // from exu:
  input                            i_exu_lden    ,
  input                            i_exu_rdwen   ,
  input         [`REG_ADDRW-1:0]   i_exu_rdid    ,
  input         [`CPU_WIDTH-1:0]   i_exu_exres   ,
  // from lsu:
  input                            i_lsu_lden    ,
  input                            i_lsu_rdwen   ,
  input         [`REG_ADDRW-1:0]   i_lsu_rdid    ,
  input         [`CPU_WIDTH-1:0]   i_lsu_exres   ,
  input         [`CPU_WIDTH-1:0]   i_lsu_lsres   ,
  // from wbu:
  input                            i_wbu_rdwen   ,
  input         [`REG_ADDRW-1:0]   i_wbu_rdid    ,
  input         [`CPU_WIDTH-1:0]   i_wbu_rd      ,
  // to id/ex:
  output logic  [`CPU_WIDTH-1:0]   o_idu_rs1     ,
  output logic  [`CPU_WIDTH-1:0]   o_idu_rs2     ,
  // to pc if/id id/ex:
  output                           o_idex_nop    ,
  output                           o_ifid_stall  ,

  // 2. from id/ex pipe reg & lsu out to generate regst for ex/ls pipe reg in:
  input         [`CPU_WIDTH-1:0]   i_exu_rs2     ,  // from id/ex pipe reg out.
//input         [`CPU_WIDTH-1:0]   i_lsu_lsres   ,  // from lsu_lsres, reg from last cycle.
  output                           o_idu_ldstbp  ,  // (load+store) bypass, to id/ex in.
  input                            i_exu_ldstbp  ,  // (load+store) bypass, from id/ex out. one cycle after o_idu_ldstbp.
  output        [`CPU_WIDTH-1:0]   o_exu_rs2     ,  // to ex/ls pipe reg in , use for lsu in next cycle.

  // 3. for sim:
  output                           s_a0zero 
);

  // 1. from exu/lsu/wbu to generate rs1/rs2 for idu: /////////////////////////////////////////////////////
  
  logic [`CPU_WIDTH-1:0] regfile_rs1,regfile_rs2;

  regfile u_regfile(
    .i_clk    (i_clk        ),
    .i_wen    (i_wbu_rdwen  ),
    .i_waddr  (i_wbu_rdid   ),
    .i_wdata  (i_wbu_rd     ),
    .i_raddr1 (i_idu_rs1id  ),
    .i_raddr2 (i_idu_rs2id  ),
    .o_rdata1 (regfile_rs1  ),
    .o_rdata2 (regfile_rs2  ),
    .s_a0zero (s_a0zero     )
  );

  always @(*) begin // 存在优先级!!
    if(!i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs1id))begin
      o_idu_rs1 = i_exu_exres;
    end else if(i_lsu_rdwen && (i_lsu_rdid == i_idu_rs1id))begin
      o_idu_rs1 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
    end else if(i_wbu_rdwen && (i_wbu_rdid == i_idu_rs1id))begin
      o_idu_rs1 = i_wbu_rd;
    end else begin
      o_idu_rs1 = regfile_rs1;
    end
  end

  always @(*) begin // 存在优先级!!
    if(!i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs2id))begin
      o_idu_rs2 = i_exu_exres;
    end else if(i_lsu_rdwen && (i_lsu_rdid == i_idu_rs2id))begin
      o_idu_rs2 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
    end else if(i_wbu_rdwen && (i_wbu_rdid == i_idu_rs2id))begin
      o_idu_rs2 = i_wbu_rd;
    end else begin
      o_idu_rs2 = regfile_rs2;
    end
  end

  assign o_idex_nop =  i_exu_lden && i_exu_rdwen && ( i_exu_rdid == i_idu_rs1id || i_exu_rdid == i_idu_rs2id ) && !o_idu_ldstbp;
  assign o_ifid_stall = o_idex_nop;

  // 2. from id/ex pipe reg & lsu out to generate regst for ex/ls pipe reg in:////////////////////////////////////
  assign o_idu_ldstbp  =  i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_idu_rs2id) && i_idu_sten;  //load + store, do not need bubble!
  assign o_exu_rs2 = i_exu_ldstbp ? i_lsu_lsres : i_exu_rs2;

endmodule
