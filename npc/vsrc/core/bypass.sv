`include "config.sv"
module bypass (
  input                            i_clk         ,

  // from idu:
  input         [`REG_ADDRW-1:0]   i_rs1id       ,
  input         [`REG_ADDRW-1:0]   i_rs2id       ,

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
  output logic  [`CPU_WIDTH-1:0]   o_rs1         ,
  output logic  [`CPU_WIDTH-1:0]   o_rs2         ,

  // to pc if/id id/ex:
  output                           o_pc_wen      ,
  output                           o_ifid_wen    ,
  output                           o_idex_bubble ,
//output                           o_exls_bypass ,

  // for sim:
  output                           s_a0zero 
);

  logic [`CPU_WIDTH-1:0] regfile_rs1,regfile_rs2;

  regfile u_regfile(
    .i_clk    (i_clk        ),
    .i_wen    (i_wbu_rdwen  ),
    .i_waddr  (i_wbu_rdid   ),
    .i_wdata  (i_wbu_rd     ),
    .i_raddr1 (i_rs1id      ),
    .i_raddr2 (i_rs2id      ),
    .o_rdata1 (regfile_rs1  ),
    .o_rdata2 (regfile_rs2  ),
    .s_a0zero (s_a0zero     )
  );

  always @(*) begin // 存在优先级!!
    if(!i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_rs1id))begin
      o_rs1 = i_exu_exres;
    end else if(i_lsu_rdwen && (i_lsu_rdid == i_rs1id))begin
      o_rs1 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
    end else if(i_wbu_rdwen && (i_wbu_rdid == i_rs1id))begin
      o_rs1 = i_wbu_rd;
    end else begin
      o_rs1 = regfile_rs1;
    end
  end

  always @(*) begin // 存在优先级!!
    if(!i_exu_lden && i_exu_rdwen && (i_exu_rdid == i_rs2id))begin
      o_rs2 = i_exu_exres;
    end else if(i_lsu_rdwen && (i_lsu_rdid == i_rs2id))begin
      o_rs2 = i_lsu_lden ? i_lsu_lsres : i_lsu_exres;
    end else if(i_wbu_rdwen && (i_wbu_rdid == i_rs2id))begin
      o_rs2 = i_wbu_rd;
    end else begin
      o_rs2 = regfile_rs2;
    end
  end

  assign o_idex_bubble = i_exu_lden && i_exu_rdwen && ( i_exu_rdid == i_rs1id || i_exu_rdid == i_rs2id );
  assign o_pc_wen      = ~ o_idex_bubble;
  assign o_ifid_wen    = ~ o_idex_bubble;

endmodule
