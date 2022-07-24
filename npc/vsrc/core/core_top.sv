`include "config.sv"
module core_top(
  input                 i_clk       ,
  input                 i_rst_n     ,
  uni_if.Master         UniIf_ifu_M ,
  uni_if.Master         UniIf_lsu_M
);

  // control signals:
  logic [`CPU_WIDTH-1:0]  pre_pc;
  logic                   ifid_nop;               // for branch adventure
  logic                   ifid_stall, idex_nop;   // for data adventure
  logic                   idu_ldstbp, exu_ldstbp; // for ld -> st bypass.
  logic                   ifu_valid , ifu_ready;  // pipeline shakehands: pc/if -> if/id
  logic                   idu_valid , idu_ready;  // pipeline shakehands: if/id -> id/ex
  logic                   exu_valid , exu_ready;  // pipeline shakehands: id/ex -> ex/ls
  logic                   lsu_valid , lsu_ready;  // pipeline shakehands: ex/ls -> ls/wb

  // simulation signals:
  logic [2:0]             s_id_err ;
  logic                   s_a0zero ;
  logic [`CPU_WIDTH-1:0]  s_idu_diffpc, s_exu_diffpc, s_lsu_diffpc, s_wbu_diffpc;
  logic [`INS_WIDTH-1:0]  s_idu_ins   , s_exu_ins   , s_lsu_ins   , s_wbu_ins   ;
  logic                   s_lsu_device, s_wbu_device;

  // 2.1 ifu ////////////////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0]  ifu_pc ;
  logic [`INS_WIDTH-1:0]  ifu_ins;

  ifu u_ifu(
    .i_clk        (i_clk      ),
  	.i_rst_n      (i_rst_n    ),
    .UniIf_M      (UniIf_ifu_M),
    .o_post_valid (ifu_valid  ),
    .i_post_ready (ifu_ready  ),
    .i_next_pc    (pre_pc     ),
    .o_ifu_pc     (ifu_pc     ),
    .o_ifu_ins    (ifu_ins    )
  );

  // 2.2 idu ////////////////////////////////////////////////////////

  // for bypass to get reg value.
  logic [`REG_ADDRW-1:0]      idu_rs1id,idu_rs2id;
  // get rs value from bypass: 
  logic [`CPU_WIDTH-1:0]      idu_rs1,idu_rs2;
  // for wbu:
  logic [`REG_ADDRW-1:0]      idu_rdid;
  logic                       idu_rdwen;
  // for exu:
  logic [`CPU_WIDTH-1:0]      idu_imm;
  logic [`EXU_SEL_WIDTH-1:0]  idu_exsrc;
  logic [`EXU_OPT_WIDTH-1:0]  idu_exopt;
  // for lsu:
  logic [2:0]                 idu_lsfunc3;
  logic                       idu_lden;
  logic                       idu_sten;
  // for bru:
  logic                       idu_jal,idu_jalr,idu_brch;
  logic [2:0]                 idu_bfun3;
  // for next stage to pipe:
  logic [`CPU_WIDTH-1:0]      idu_pc;

  idu u_idu(
    .i_clk         (i_clk        ),
    .i_rst_n       (i_rst_n      ),
    .i_pre_nop     (ifid_nop     ),
    .i_pre_stall   (ifid_stall   ),
    .i_pre_valid   (ifu_valid    ),
    .o_pre_ready   (ifu_ready    ),
    .o_post_valid  (idu_valid    ),
    .i_post_ready  (idu_ready    ),
    .i_ifu_ins     (ifu_ins      ),
    .i_ifu_pc      (ifu_pc       ),
    .o_idu_rs1id   (idu_rs1id    ),
    .o_idu_rs2id   (idu_rs2id    ),
    .o_idu_rdid    (idu_rdid     ),
    .o_idu_rdwen   (idu_rdwen    ),
    .o_idu_imm     (idu_imm      ),
    .o_idu_exsrc   (idu_exsrc    ),
    .o_idu_exopt   (idu_exopt    ),
    .o_idu_lsfunc3 (idu_lsfunc3  ),
    .o_idu_lden    (idu_lden     ),
    .o_idu_sten    (idu_sten     ),
    .o_idu_jal     (idu_jal      ),
    .o_idu_jalr    (idu_jalr     ),
    .o_idu_brch    (idu_brch     ),
    .o_idu_bfun3   (idu_bfun3    ),
    .o_idu_pc      (idu_pc       ),
    .s_idu_diffpc  (s_idu_diffpc ),
    .s_idu_iderr   (s_id_err     ),
    .s_idu_ins     (s_idu_ins    )
  );

  // 2.3 exu ///////////////////////////////////////////////

  // generate exu output value:
  logic [`CPU_WIDTH-1:0]      exu_exres;
  // bypss: 
  logic [`CPU_WIDTH-1:0]      exu_rs2;    // from exu to bypass unit.
  logic [`CPU_WIDTH-1:0]      exu_rs2_bp; // from bypss unit to lsu input for store ins.
  // for lsu:
  logic [2:0]                 exu_lsfunc3;
  logic                       exu_lden,exu_sten;
  // for wbu:
  logic [`REG_ADDRW-1:0]      exu_rdid;
  logic                       exu_rdwen;

  exu u_exu(
    .i_clk         (i_clk         ),
    .i_rst_n       (i_rst_n       ),
    .i_pre_nop     (idex_nop      ),
    .i_pre_valid   (idu_valid     ),
    .o_pre_ready   (idu_ready     ),
    .o_post_valid  (exu_valid     ),
    .i_post_ready  (exu_ready     ),
    .i_idu_imm     (idu_imm       ),
    .i_idu_rs1     (idu_rs1       ),
    .i_idu_rs2     (idu_rs2       ),
    .i_idu_rdid    (idu_rdid      ),
    .i_idu_rdwen   (idu_rdwen     ),
    .i_idu_exsrc   (idu_exsrc     ),
    .i_idu_exopt   (idu_exopt     ),
    .i_idu_lsfunc3 (idu_lsfunc3   ),
    .i_idu_lden    (idu_lden      ),
    .i_idu_sten    (idu_sten      ),
    .i_idu_ldstbp  (idu_ldstbp    ),
    .i_idu_pc      (idu_pc        ),
    .s_idu_diffpc  (s_idu_diffpc  ),
    .s_idu_ins     (s_idu_ins     ),
    .o_exu_res     (exu_exres     ),
    .o_exu_rs2     (exu_rs2       ),
    .o_exu_lsfunc3 (exu_lsfunc3   ),
    .o_exu_lden    (exu_lden      ),
    .o_exu_sten    (exu_sten      ),
    .o_exu_ldstbp  (exu_ldstbp    ),
    .o_exu_rdid    (exu_rdid      ),
    .o_exu_rdwen   (exu_rdwen     ),
    .s_exu_diffpc  (s_exu_diffpc  ),
    .s_exu_ins     (s_exu_ins     )
  );

  // 2.4 lsu ///////////////////////////////////////////////

  logic [`CPU_WIDTH-1:0]      lsu_exres;
  logic [`CPU_WIDTH-1:0]      lsu_lsres;
  logic                       lsu_lden ;
  logic [`REG_ADDRW-1:0]      lsu_rdid ;
  logic                       lsu_rdwen;

  lsu u_lsu(
    .i_clk         (i_clk         ),
    .i_rst_n       (i_rst_n       ),
    .UniIf_M       (UniIf_lsu_M   ),
    .i_pre_valid   (exu_valid     ),
    .o_pre_ready   (exu_ready     ),
    .o_post_valid  (lsu_valid     ),
    .i_post_ready  (lsu_ready     ),
    .i_exu_exres   (exu_exres     ),
    .i_exu_rs2     (exu_rs2_bp    ),
    .i_exu_rdid    (exu_rdid      ),
    .i_exu_rdwen   (exu_rdwen     ),
    .i_exu_lsfunc3 (exu_lsfunc3   ),
    .i_exu_lden    (exu_lden      ),
    .i_exu_sten    (exu_sten      ),
    .s_exu_diffpc  (s_exu_diffpc  ),
    .s_exu_ins     (s_exu_ins     ),
    .o_lsu_lsres   (lsu_lsres     ),
    .o_lsu_exres   (lsu_exres     ),
    .o_lsu_lden    (lsu_lden      ),
    .o_lsu_rdid    (lsu_rdid      ),
    .o_lsu_rdwen   (lsu_rdwen     ),
    .s_lsu_diffpc  (s_lsu_diffpc  ),
    .s_lsu_ins     (s_lsu_ins     ),
    .s_lsu_device  (s_lsu_device  )
  );

  // 2.5 wbu ///////////////////////////////////////////////

  logic [`CPU_WIDTH-1:0]      wbu_rd;
  logic [`REG_ADDRW-1:0]      wbu_rdid;
  logic                       wbu_rdwen;

  wbu u_wbu(
    .i_clk        (i_clk        ),
    .i_rst_n      (i_rst_n      ),
    .i_pre_valid  (lsu_valid    ),
    .o_pre_ready  (lsu_ready    ),
    .i_lsu_exres  (lsu_exres    ),
    .i_lsu_lsres  (lsu_lsres    ),
    .i_lsu_rdid   (lsu_rdid     ),
    .i_lsu_rdwen  (lsu_rdwen    ),
    .i_lsu_lden   (lsu_lden     ),
    .s_lsu_diffpc (s_lsu_diffpc ),
    .s_lsu_ins    (s_lsu_ins    ),
    .s_lsu_device (s_lsu_device ),
    .o_wbu_rdwen  (wbu_rdwen    ),
    .o_wbu_rd     (wbu_rd       ),
    .o_wbu_rdid   (wbu_rdid     ),
    .s_wbu_diffpc (s_wbu_diffpc ),
    .s_wbu_ins    (s_wbu_ins    ),
    .s_wbu_device (s_wbu_device )
  );

  // 2.6 bypass, regfile read/write. ///////////////////////
  bypass u_bypass(
  	.i_clk        (i_clk        ),
    // generate rs1,rs2:
    .i_idu_rs1id  (idu_rs1id    ),
    .i_idu_rs2id  (idu_rs2id    ),
    .i_idu_sten   (idu_sten     ),
    .i_exu_lden   (exu_lden     ),
    .i_exu_rdwen  (exu_rdwen    ),
    .i_exu_rdid   (exu_rdid     ),
    .i_exu_exres  (exu_exres    ),
    .i_lsu_lden   (lsu_lden     ),
    .i_lsu_rdwen  (lsu_rdwen    ),
    .i_lsu_rdid   (lsu_rdid     ),
    .i_lsu_exres  (lsu_exres    ),
    .i_lsu_lsres  (lsu_lsres    ),
    .i_wbu_rdwen  (wbu_rdwen    ),
    .i_wbu_rdid   (wbu_rdid     ),
    .i_wbu_rd     (wbu_rd       ),
    .o_idu_rs1    (idu_rs1      ),
    .o_idu_rs2    (idu_rs2      ),
    .o_idex_nop   (idex_nop     ),
    .o_ifid_stall (ifid_stall   ),
    // generate regst:
    .i_exu_rs2    (exu_rs2      ),
    .o_idu_ldstbp (idu_ldstbp   ),
    .i_exu_ldstbp (exu_ldstbp   ),
    .o_exu_rs2    (exu_rs2_bp   ),
    .s_a0zero     (s_a0zero     )
  );

  // 2.7 bru ///////////////////////////////////////////////

  bru u_bru(
    .i_clk      (i_clk      ),
    .i_rst_n    (i_rst_n    ),
    .i_idu_valid(idu_valid  ),
    .i_idu_rs1id(idu_rs1id  ),
    .i_exu_rdid (exu_rdid   ),
    .i_jal      (idu_jal    ),
    .i_jalr     (idu_jalr   ),
    .i_brch     (idu_brch   ),
    .i_bfun3    (idu_bfun3  ),
    .i_rs1      (idu_rs1    ),
    .i_rs2      (idu_rs2    ),
    .i_imm      (idu_imm    ),
    .i_ifupc    (ifu_pc     ),
    .i_idupc    (idu_pc     ),
    .o_next_pc  (pre_pc     ),
    .o_ifid_nop (ifid_nop   )
  );

  // 3.sim:  ////////////////////////////////////////////////////////
  // 3.1 update rst state, wb stage pc, wr/rd device to sim.
  import "DPI-C" function void check_rst(input bit rst_flag);
  import "DPI-C" function void diff_read_pc(input longint rtl_pc);
  import "DPI-C" function void diff_skip_device(input bit s_wbu_device);
  always @(*) begin
    check_rst(i_rst_n);
    diff_read_pc(s_wbu_diffpc);
    diff_skip_device(s_wbu_device);
  end


  // 3.2 update wb stage finish.
  import "DPI-C" function void check_finsih(input int ins,input bit a0zero);
  always@(*)begin
    check_finsih(s_wbu_ins[`INS_WIDTH-1:0],s_a0zero);
  end

  // 3.3 check id error.
  always@(*)begin
    if(i_rst_n & (idu_pc >= 64'h80000000) & s_id_err[0]) $display("\n----------ins opcode error, pc = %x, ins = %x, opcode == %b---------------\n",idu_pc,s_idu_ins,s_idu_ins[ 6: 0] );
    if(i_rst_n & (idu_pc >= 64'h80000000) & s_id_err[1]) $display("\n----------ins funct3 error, pc = %x, ins = %x, funct3 == %b---------------\n",idu_pc,s_idu_ins,s_idu_ins[14:12] );
    if(i_rst_n & (idu_pc >= 64'h80000000) & s_id_err[2]) $display("\n----------ins funct7 error, pc = %x, ins = %x, funct7 == %b---------------\n",idu_pc,s_idu_ins,s_idu_ins[31:25] );
    if(i_rst_n & (idu_pc >= 64'h80000000) & |s_id_err ) $finish; //ins docode err.
  end

endmodule
