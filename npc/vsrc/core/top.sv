`include "config.sv"
module top(
  input                 i_clk   ,
  input                 i_rst_n
);
  //1.rst : ////////////////////////////////////////////////////////
  logic rst_n_sync;
  stdrst u_stdrst(
  	.i_clk        (i_clk      ),
    .i_rst_n      (i_rst_n    ),
    .o_rst_n_sync (rst_n_sync )
  );
  
  //2.cpu:  ////////////////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] pc;

  // simulation signals:
  logic [2:0]            s_id_err;
  logic                  s_a0zero;

  // control signals:
  logic ifid_pause, if_valid, id_ready;
  logic idex_pause, id_valid, ex_ready;
  logic exls_pause, ex_valid, ls_ready;
  logic lswb_pause, ls_valid, wb_ready;
  logic bru_pause;

  // 2.1 ifu -> idu.///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] ifid_i_pc, ifid_o_pc ;
  logic [`INS_WIDTH-1:0] ifid_i_ins,ifid_o_ins;

  ifu u_ifu(
    .i_rst_n (rst_n_sync),
    .i_pc    (pc        ),
    .o_ins   (ifid_i_ins)
  );

  assign ifid_i_pc = pc;

  pipe_if_id u_pipe_if_id(
    .i_clk       (i_clk       ),
    .i_rst_n     (i_rst_n     ),
    .i_pause     (ifid_pause  ),
    .i_ifu_valid (if_valid    ),
    .i_idu_ready (id_ready    ),
    .i_ifu_pc    (ifid_i_pc   ),
    .i_ifu_ins   (ifid_i_ins  ),
    .o_idu_pc    (ifid_o_pc   ),
    .o_idu_ins   (ifid_o_ins  )
  );

  // 2.2 idu -> exu. ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]     idex_i_pc ,     idex_o_pc ;
  logic [`CPU_WIDTH-1:0]     idex_i_imm,     idex_o_imm;
  logic [`CPU_WIDTH-1:0]     idex_i_rs1,     idex_o_rs1;
  logic [`CPU_WIDTH-1:0]     idex_i_rs2,     idex_o_rs2;
  logic [`REG_ADDRW-1:0]     idex_i_rdid,    idex_o_rdid;
  logic                      idex_i_rdwen,   idex_o_rdwen;
  logic [`EXU_SEL_WIDTH-1:0] idex_i_src_sel, idex_o_src_sel;
  logic [`EXU_OPT_WIDTH-1:0] idex_i_exopt,   idex_o_exopt;
  logic [`LSU_OPT_WIDTH-1:0] idex_i_lsopt,   idex_o_lsopt;
  logic [`REG_ADDRW-1:0]     id_rs1id,       id_rs2id;
  logic                      idbr_jal,       idbr_jalr;
  logic [2:0]                idbr_brch;
  
  idu u_idu(
    .i_ins         (ifid_o_ins    ),
    .o_rs1id       (id_rs1id      ),  //for regfile, to get idex_i_rs1
    .o_rs2id       (id_rs2id      ),  //for regfile, to get idex_i_rs2
    .o_rdid        (idex_i_rdid   ),
    .o_rdwen       (idex_i_rdwen  ),
    .o_imm         (idex_i_imm    ),
    .o_exu_src_sel (idex_i_src_sel),
    .o_exu_opt     (idex_i_exopt  ),
    .o_lsu_opt     (idex_i_lsopt  ),
    .o_brch        (idbr_brch     ),
    .o_jal         (idbr_jal      ),
    .o_jalr        (idbr_jalr     ),
    .s_id_err      (s_id_err      )
  );

  assign idex_i_pc = ifid_o_pc;

  pipe_id_ex u_pipe_id_ex(
    .i_clk         (i_clk         ),
    .i_rst_n       (i_rst_n       ),
    .i_pause       (idex_pause    ),
    .i_idu_valid   (id_valid      ),
    .i_exu_ready   (ex_ready      ),
    .i_idu_pc      (idex_i_pc     ),
    .i_idu_imm     (idex_i_imm    ),
    .i_idu_rs1     (idex_i_rs1    ),
    .i_idu_rs2     (idex_i_rs2    ),
    .i_idu_rdid    (idex_i_rdid   ),
    .i_idu_rdwen   (idex_i_rdwen  ),
    .i_idu_src_sel (idex_i_src_sel),
    .i_idu_exopt   (idex_i_exopt  ),
    .i_idu_lsopt   (idex_i_lsopt  ),
    .o_exu_pc      (idex_o_pc     ),
    .o_exu_imm     (idex_o_imm    ),
    .o_exu_rs1     (idex_o_rs1    ),
    .o_exu_rs2     (idex_o_rs2    ),
    .o_exu_rdid    (idex_o_rdid   ),
    .o_exu_rdwen   (idex_o_rdwen  ),
    .o_exu_src_sel (idex_o_src_sel),
    .o_exu_exopt   (idex_o_exopt  ),
    .o_exu_lsopt   (idex_o_lsopt  )
  );

  // 2.3 exu -> lsu. ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]      exls_i_exres, exls_o_exres;
  logic [`CPU_WIDTH-1:0]      exls_i_rs2  , exls_o_rs2  ;
  logic [`REG_ADDRW-1:0]      exls_i_rdid , exls_o_rdid ;
  logic                       exls_i_rdwen, exls_o_rdwen;
  logic [`LSU_OPT_WIDTH-1:0]  exls_i_lsopt, exls_o_lsopt;

  exu u_exu(
  	.i_pc      (idex_o_pc     ),
    .i_rs1     (idex_o_rs1    ),
    .i_rs2     (idex_o_rs2    ),
    .i_imm     (idex_o_imm    ),
    .i_src_sel (idex_o_src_sel),
    .i_exopt   (idex_o_exopt  ),
    .o_exu_res (exls_i_exres  )
  );

  assign exls_i_rs2   = idex_o_rs2;
  assign exls_i_rdid  = idex_o_rdid;
  assign exls_i_rdwen = idex_o_rdwen;
  assign exls_i_lsopt = idex_o_lsopt;

  pipe_ex_ls u_pipe_ex_ls(
  	.i_clk       (i_clk       ),
    .i_rst_n     (i_rst_n     ),
    .i_pause     (exls_pause  ),
    .i_exu_valid (ex_valid    ),
    .i_lsu_ready (ls_ready    ),
    .i_exu_exres (exls_i_exres),
    .i_exu_rs2   (exls_i_rs2  ),
    .i_exu_rdid  (exls_i_rdid ),
    .i_exu_rdwen (exls_i_rdwen),
    .i_exu_lsopt (exls_i_lsopt),
    .o_lsu_exres (exls_o_exres),
    .o_lsu_rs2   (exls_o_rs2  ),
    .o_lsu_rdid  (exls_o_rdid ),
    .o_lsu_rdwen (exls_o_rdwen),
    .o_lsu_lsopt (exls_o_lsopt)
  );
  
  // 2.4 lsu -> wbu. ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]      lswb_i_exres , lswb_o_exres ;
  logic [`CPU_WIDTH-1:0]      lswb_i_lsres , lswb_o_lsres ;
  logic [`REG_ADDRW-1:0]      lswb_i_rdid  , lswb_o_rdid  ;
  logic                       lswb_i_rdwen , lswb_o_rdwen ;
  logic                       lswb_i_ldflag, lswb_o_ldflag;

  lsu u_lsu(
    .i_clk   (i_clk       ),
    .i_rst_n (i_rst_n     ),
    .i_opt   (exls_o_lsopt),
    .i_addr  (exls_o_exres),
    .i_regst (exls_o_rs2  ),
    .o_regld (lswb_i_lsres)
  );

  assign lswb_i_exres  = exls_o_exres;
  assign lswb_i_rdid   = exls_o_rdid;
  assign lswb_i_rdwen  = exls_o_rdwen;
  assign lswb_i_ldflag = ~exls_o_lsopt[0];

  pipe_ls_wb u_pipe_ls_wb(
    .i_clk        (i_clk        ),
    .i_rst_n      (i_rst_n      ),
    .i_pause      (lswb_pause   ),
    .i_lsu_valid  (ls_valid     ),
    .i_wbu_ready  (wb_ready     ),
    .i_lsu_exres  (lswb_i_exres ),
    .i_lsu_lsres  (lswb_i_lsres ),
    .i_lsu_rdid   (lswb_i_rdid  ),
    .i_lsu_rdwen  (lswb_i_rdwen ),
    .i_lsu_ldflag (lswb_i_ldflag),
    .o_wbu_exres  (lswb_o_exres ),
    .o_wbu_lsres  (lswb_o_lsres ),
    .o_wbu_rdid   (lswb_o_rdid  ),
    .o_wbu_rdwen  (lswb_o_rdwen ),
    .o_wbu_ldflag (lswb_o_ldflag)
  );

  // 2.5 wbu. ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] wb_rd;
  wbu u_wbu(
    .i_exu_res (lswb_o_exres ),
    .i_lsu_res (lswb_o_lsres ),
    .i_ldflag  (lswb_o_ldflag),
    .o_rd      (wb_rd        )
  );

  regfile u_regfile(
    .i_clk    (i_clk        ),
    .i_wen    (lswb_o_rdwen ),
    .i_waddr  (lswb_o_rdid  ),
    .i_wdata  (wb_rd        ),
    .i_raddr1 (id_rs1id     ),
    .i_raddr2 (id_rs2id     ),
    .o_rdata1 (idex_i_rs1   ),
    .o_rdata2 (idex_i_rs2   ),
    .s_a0zero (s_a0zero     )
  );

  // 2.6 bru. ///////////////////////////////////////////////
  bru u_bru(
    .i_clk   (i_clk     ),
    .i_rst_n (rst_n_sync),
    .i_pause (bru_pause ),
    .i_brch  (idbr_brch ),
    .i_jal   (idbr_jal  ),
    .i_jalr  (idbr_jalr ),
    .i_rs1   (idex_i_rs1),
    .i_rs2   (idex_i_rs2),
    .i_imm   (idex_i_imm),
    .i_prepc (idex_i_pc ),
    .o_pc    (pc        )
  );

  //3.sim:  ////////////////////////////////////////////////////////
  import "DPI-C" function void check_rst(input bit rst_flag);
  import "DPI-C" function bit check_finsih(input int finish_flag);
  always@(*)begin
    check_rst(rst_n_sync);
    if(check_finsih(ifid_o_ins))begin  //ins == ebreak.
      $display("\n----------EBREAK: HIT !!%s!! TRAP!!---------------\n",s_a0zero? "GOOD":"BAD");
      $finish;
    end
    if(rst_n_sync & |ifid_o_ins & s_id_err[0]) $display("\n----------ins decode error, pc = %x, opcode == %b---------------\n",ifid_o_pc,ifid_o_ins[ 6: 0] );
    if(rst_n_sync & |ifid_o_ins & s_id_err[1]) $display("\n----------ins decode error, pc = %x, funct3 == %b---------------\n",ifid_o_pc,ifid_o_ins[14:12] );
    if(rst_n_sync & |ifid_o_ins & s_id_err[2]) $display("\n----------ins decode error, pc = %x, funct7 == %b---------------\n",ifid_o_pc,ifid_o_ins[31:25] );
    if(rst_n_sync & |ifid_o_ins & |s_id_err ) $finish; //ins docode err.
  end

endmodule
