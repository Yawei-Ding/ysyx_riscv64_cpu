`include "config.sv"
module top(
  input                 i_clk   ,
  input                 i_rst_n
);
  // 1.rst : ////////////////////////////////////////////////////////
  logic rst_n_sync;
  stl_rst u_stl_rst(
  	.i_clk        (i_clk      ),
    .i_rst_n      (i_rst_n    ),
    .o_rst_n_sync (rst_n_sync )
  );
  
  // 2.cpu:  ////////////////////////////////////////////////////////
  // control signals:
  logic [`CPU_WIDTH-1:0]  pc;
  logic                   ifid_nop;               // for branch adventure
  logic                   ifid_stall, idex_nop;   // for data adventure
  logic                   idu_ldstbp, exu_ldstbp; // for ld -> st bypass.
  logic                   ifu_valid,ifu_ready;    // pipeline shakehands: pc/if -> if/id
  logic                   idu_valid,idu_ready;    // pipeline shakehands: if/id -> id/ex
  logic                   exu_valid,exu_ready;    // pipeline shakehands: id/ex -> ex/ls
  logic                   lsu_valid,lsu_ready;    // pipeline shakehands: ex/ls -> ls/wb
  logic                   wbu_valid,wbu_ready;    // pipeline shakehands: ls/wb -> wb/regfile.

  // simulation signals:
  logic [2:0]             s_id_err;
  logic                   s_a0zero;
  logic [`CPU_WIDTH-1:0]  s_idu_diffpc,s_exu_diffpc,s_lsu_diffpc,s_wbu_diffpc;

  // 2.1 ifu ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]  ifu_pc,ifu_pc_r;
  logic [`INS_WIDTH-1:0]  ifu_ins,ifu_ins_r;

  assign ifu_pc = pc;

  ifu u_ifu(
  	.i_rst_n (rst_n_sync),
    .i_pc    (ifu_pc    ),
    .o_ins   (ifu_ins   )
  );

  pipe_if_id u_pipe_if_id(
    .i_clk        (i_clk        ),
    .i_rst_n      (rst_n_sync   ),
    .i_nop        (ifid_nop     ),
    .i_stall      (ifid_stall   ),
    .i_pre_valid  (ifu_valid    ),
    .o_pre_ready  (ifu_ready    ),
    .o_post_valid (idu_valid    ),
    .i_post_ready (idu_ready    ),
    .i_ifu_ins    (ifu_ins      ),
    .i_ifu_pc     (ifu_pc       ),
    .o_idu_ins    (ifu_ins_r    ),
    .o_idu_pc     (ifu_pc_r     ),
    .s_idu_diffpc (s_idu_diffpc )
  );

  // 2.2 idu ///////////////////////////////////////////////
  // for next stage:
  logic [`REG_ADDRW-1:0]      idu_rs1id,idu_rs2id;
  logic [`REG_ADDRW-1:0]      idu_rdid,idu_rdid_r;
  logic                       idu_rdwen,idu_rdwen_r;
  logic [`CPU_WIDTH-1:0]      idu_imm,idu_imm_r;
  logic [`CPU_WIDTH-1:0]      idu_rs1,idu_rs1_r;
  logic [`CPU_WIDTH-1:0]      idu_rs2,idu_rs2_r;
  logic [`EXU_SEL_WIDTH-1:0]  idu_src_sel,idu_src_sel_r;
  logic [`EXU_OPT_WIDTH-1:0]  idu_exopt,idu_exopt_r;
  logic [2:0]                 idu_lsfunc3,idu_lsfunc3_r;
  logic                       idu_lden,idu_lden_r;
  logic                       idu_sten,idu_sten_r;
  logic [`CPU_WIDTH-1:0]      idu_pc,idu_pc_r;
  // for branch uint:
  logic                       idu_jal,idu_jalr,idu_brch;
  logic [2:0]                 idu_bfun3;

  idu u_idu(
    .i_ins       (ifu_ins_r   ),
    .o_rs1id     (idu_rs1id   ),
    .o_rs2id     (idu_rs2id   ),
    .o_rdid      (idu_rdid    ),
    .o_rdwen     (idu_rdwen   ),
    .o_imm       (idu_imm     ),
    .o_src_sel   (idu_src_sel ),
    .o_exopt     (idu_exopt   ),
    .o_lsu_func3 (idu_lsfunc3 ),
    .o_lsu_lden  (idu_lden    ),
    .o_lsu_sten  (idu_sten    ),
    .o_jal       (idu_jal     ),
    .o_jalr      (idu_jalr    ),
    .o_brch      (idu_brch    ),
    .o_bfun3     (idu_bfun3   ),
    .s_id_err    (s_id_err    )
  );

  assign idu_pc = ifu_pc_r;

  pipe_id_ex u_pipe_id_ex(
    .i_clk         (i_clk         ),
    .i_rst_n       (rst_n_sync    ),
    .i_nop         (idex_nop      ),
    .i_pre_valid   (idu_valid     ),
    .o_pre_ready   (idu_ready     ),
    .o_post_valid  (exu_valid     ),
    .i_post_ready  (exu_ready     ),
    .i_idu_imm     (idu_imm       ),
    .i_idu_rs1     (idu_rs1       ),
    .i_idu_rs2     (idu_rs2       ),
    .i_idu_rdid    (idu_rdid      ),
    .i_idu_rdwen   (idu_rdwen     ),
    .i_idu_src_sel (idu_src_sel   ),
    .i_idu_exopt   (idu_exopt     ),
    .i_idu_func3   (idu_lsfunc3   ),
    .i_idu_lden    (idu_lden      ),
    .i_idu_sten    (idu_sten      ),
    .i_idu_ldstbp  (idu_ldstbp    ),
    .i_idu_pc      (idu_pc        ),
    .s_idu_diffpc  (s_idu_diffpc  ),
    .o_exu_imm     (idu_imm_r     ),
    .o_exu_rs1     (idu_rs1_r     ),
    .o_exu_rs2     (idu_rs2_r     ),
    .o_exu_rdid    (idu_rdid_r    ),
    .o_exu_rdwen   (idu_rdwen_r   ),
    .o_exu_src_sel (idu_src_sel_r ),
    .o_exu_exopt   (idu_exopt_r   ),
    .o_exu_func3   (idu_lsfunc3_r ),
    .o_exu_lden    (idu_lden_r    ),
    .o_exu_sten    (idu_sten_r    ),
    .o_exu_ldstbp  (exu_ldstbp    ),
    .o_exu_pc      (idu_pc_r      ),
    .s_exu_diffpc  (s_exu_diffpc  )
  );

  // 2.3 exu ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]      exu_exres,exu_exres_r;
  logic [`CPU_WIDTH-1:0]      exu_rs2,exu_rs2_bp,exu_rs2_r;
  logic [`REG_ADDRW-1:0]      exu_rdid,exu_rdid_r;
  logic                       exu_rdwen,exu_rdwen_r;
  logic [2:0]                 exu_lsfunc3,exu_lsfunc3_r;
  logic                       exu_lden,exu_lden_r;
  logic                       exu_sten,exu_sten_r;

  exu u_exu(
    .i_pc      (idu_pc_r      ),
    .i_rs1     (idu_rs1_r     ),
    .i_rs2     (idu_rs2_r     ),
    .i_imm     (idu_imm_r     ),
    .i_src_sel (idu_src_sel_r ),
    .i_exopt   (idu_exopt_r   ),
    .o_exu_res (exu_exres     )
  );

  assign exu_rs2 = idu_rs2_r;
  assign exu_rdid = idu_rdid_r;
  assign exu_rdwen = idu_rdwen_r;
  assign exu_lsfunc3 = idu_lsfunc3_r;
  assign exu_lden = idu_lden_r;
  assign exu_sten = idu_sten_r;

  pipe_ex_ls u_pipe_ex_ls(
    .i_clk        (i_clk        ),
    .i_rst_n      (rst_n_sync   ),
    .i_pre_valid  (exu_valid    ),
    .o_pre_ready  (exu_ready    ),
    .o_post_valid (lsu_valid    ),
    .i_post_ready (lsu_ready    ),
    .i_exu_exres  (exu_exres    ),
    .i_exu_rs2    (exu_rs2_bp   ),
    .i_exu_rdid   (exu_rdid     ),
    .i_exu_rdwen  (exu_rdwen    ),
    .i_exu_func3  (exu_lsfunc3  ),
    .i_exu_lden   (exu_lden     ),
    .i_exu_sten   (exu_sten     ),
    .s_exu_diffpc (s_exu_diffpc ),
    .o_lsu_exres  (exu_exres_r  ),
    .o_lsu_rs2    (exu_rs2_r    ),
    .o_lsu_rdid   (exu_rdid_r   ),
    .o_lsu_rdwen  (exu_rdwen_r  ),
    .o_lsu_func3  (exu_lsfunc3_r),
    .o_lsu_lden   (exu_lden_r   ),
    .o_lsu_sten   (exu_sten_r   ),
    .s_lsu_diffpc (s_lsu_diffpc )
  );

  // 2.4 lsu ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]      lsu_exres,lsu_exres_r;
  logic [`CPU_WIDTH-1:0]      lsu_lsres,lsu_lsres_r;
  logic                       lsu_lden, lsu_lden_r;
  logic [`REG_ADDRW-1:0]      lsu_rdid, lsu_rdid_r;
  logic                       lsu_rdwen,lsu_rdwen_r;

  lsu u_lsu(
    .i_clk     (i_clk         ),
    .i_lsfunc3 (exu_lsfunc3_r ),
    .i_lden    (exu_lden_r    ),
    .i_sten    (exu_sten_r    ),
    .i_addr    (exu_exres_r   ),
    .i_regst   (exu_rs2_r     ),
    .o_regld   (lsu_lsres     )
  );

  assign lsu_exres = exu_exres_r;
  assign lsu_lden  = exu_lden_r;
  assign lsu_rdid  = exu_rdid_r;
  assign lsu_rdwen = exu_rdwen_r;

  pipe_ls_wb u_pipe_ls_wb(
    .i_clk        (i_clk        ),
    .i_rst_n      (rst_n_sync   ),
    .i_pre_valid  (lsu_valid    ),
    .o_pre_ready  (lsu_ready    ),
    .o_post_valid (wbu_valid    ),
    .i_post_ready (wbu_ready    ),
    .i_lsu_exres  (lsu_exres    ),
    .i_lsu_lsres  (lsu_lsres    ),
    .i_lsu_rdid   (lsu_rdid     ),
    .i_lsu_rdwen  (lsu_rdwen    ),
    .i_lsu_lden   (lsu_lden     ),
    .s_lsu_diffpc (s_lsu_diffpc ),
    .o_wbu_exres  (lsu_exres_r  ),
    .o_wbu_lsres  (lsu_lsres_r  ),
    .o_wbu_rdid   (lsu_rdid_r   ),
    .o_wbu_rdwen  (lsu_rdwen_r  ),
    .o_wbu_lden   (lsu_lden_r   ),
    .s_wbu_diffpc (s_wbu_diffpc )
  );

  // 2.5 wbu ///////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]      wbu_rd;
  logic [`REG_ADDRW-1:0]      wbu_rdid;
  logic                       wbu_rdwen;

  assign wbu_rdid  = lsu_rdid_r ;

  wbu u_wbu(
    .i_pre_valid (wbu_valid   ),
    .o_pre_ready (wbu_ready   ),
    .i_rdwen     (lsu_rdwen_r ),
    .i_exu_res   (lsu_exres_r ),
    .i_lsu_res   (lsu_lsres_r ),
    .i_ldflag    (lsu_lden_r  ),
    .o_rdwen     (wbu_rdwen   ),
    .o_rd        (wbu_rd      )
  );

  // 2.6 bypass, regfile read/write. ///////////////////////
  bypass u_bypass(
  	.i_clk        (i_clk        ),
    // generate rs1,rs2:
    .i_idu_rs1id  (idu_rs1id     ),
    .i_idu_rs2id  (idu_rs2id     ),
    .i_idu_sten   (idu_sten      ),
    .i_exu_lden   (exu_lden      ),
    .i_exu_rdwen  (exu_rdwen     ),
    .i_exu_rdid   (exu_rdid      ),
    .i_exu_exres  (exu_exres     ),
    .i_lsu_lden   (lsu_lden      ),
    .i_lsu_rdwen  (lsu_rdwen     ),
    .i_lsu_rdid   (lsu_rdid      ),
    .i_lsu_exres  (lsu_exres     ),
    .i_lsu_lsres  (lsu_lsres     ),
    .i_wbu_rdwen  (wbu_rdwen     ),
    .i_wbu_rdid   (wbu_rdid      ),
    .i_wbu_rd     (wbu_rd        ),
    .o_idu_rs1    (idu_rs1       ),
    .o_idu_rs2    (idu_rs2       ),
    .o_idex_nop   (idex_nop      ),
    .o_ifid_stall (ifid_stall    ),
    // generate regst:
    .i_exu_rs2    (exu_rs2      ),
    .o_idu_ldstbp (idu_ldstbp   ),
    .i_exu_ldstbp (exu_ldstbp   ),
    .o_exu_rs2    (exu_rs2_bp   ),
    .s_a0zero     (s_a0zero     )
  );
  

  // 2.7 bru ///////////////////////////////////////////////

  bru u_bru(
    .i_clk        (i_clk       ),
    .i_rst_n      (rst_n_sync  ),
    .o_post_valid (ifu_valid   ),
    .i_post_ready (ifu_ready   ),
    .i_jal        (idu_jal     ),
    .i_jalr       (idu_jalr    ),
    .i_brch       (idu_brch    ),
    .i_bfun3      (idu_bfun3   ),
    .i_rs1        (idu_rs1     ),
    .i_rs2        (idu_rs2     ),
    .i_imm        (idu_imm     ),
    .i_prepc      (idu_pc      ),
    .o_pc         (pc          ),
    .o_ifid_nop   (ifid_nop    )
  );


  // 3.sim:  ////////////////////////////////////////////////////////
  // 3.1 update rst state and wb stage pc to sim.
  import "DPI-C" function void check_rst(input bit rst_flag);
  import "DPI-C" function void diff_read_pc(input longint rtl_pc);
  always @(*) begin
    check_rst(rst_n_sync);
    diff_read_pc(s_wbu_diffpc);
  end

  // 3.2 update wb stage finish.
  import "DPI-C" function void rtl_pmem_read (input longint raddr, output longint rdata, input bit ren);
  import "DPI-C" function bit check_finsih(input int ins);
  wire [`CPU_WIDTH-1:0] s_wbu_ins;
  always@(*)begin
    rtl_pmem_read (s_wbu_diffpc, s_wbu_ins, i_rst_n);
    if(check_finsih({s_wbu_ins & `CPU_WIDTH'h00000000FFFFFFFF}[`INS_WIDTH-1:0]))begin  //ins == ebreak.
      $display("\n----------EBREAK: HIT !!%s!! TRAP!!---------------\n",s_a0zero? "GOOD":"BAD");
      $finish;
    end
  end

  always@(*)begin
    if(rst_n_sync & |ifu_ins_r & s_id_err[0]) $display("\n----------ins decode error, pc = %x, opcode == %b---------------\n",ifu_pc_r,ifu_ins_r[ 6: 0] );
    if(rst_n_sync & |ifu_ins_r & s_id_err[1]) $display("\n----------ins decode error, pc = %x, funct3 == %b---------------\n",ifu_pc_r,ifu_ins_r[14:12] );
    if(rst_n_sync & |ifu_ins_r & s_id_err[2]) $display("\n----------ins decode error, pc = %x, funct7 == %b---------------\n",ifu_pc_r,ifu_ins_r[31:25] );
    if(rst_n_sync & |ifu_ins_r & |s_id_err ) $finish; //ins docode err.
  end


endmodule
