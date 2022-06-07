`include "config.sv"
module top(
  input                 i_clk   ,
  input                 i_rst_n
);
  //1.rst : ////////////////////////////////////////////////////////
  logic rst_n_sync;
  stdrst u_stdrst(
  	.i_clk        (i_clk        ),
    .i_rst_n      (i_rst_n      ),
    .o_rst_n_sync (rst_n_sync   )
  );
  
  //2.cpu:  /////////////////////////////////////////////////
  logic [31:0]           ins;             // ifu -> idu.
  logic [`CPU_WIDTH-1:0] pc;              // pcu -> ifu.
  logic [`REG_ADDRW-1:0] rs1id,rs2id,rdid;// idu -> reg.
  logic [`EXU_OPT_WIDTH-1:0] exu_opt;     // idu -> exu.
  logic [`EXU_SEL_WIDTH-1:0] exu_src_sel; // idu -> exu.
  logic [`LSU_OPT_WIDTH-1:0] lsu_opt;     // idu -> lsu.

  logic [`CPU_WIDTH-1:0] rs1,rs2,imm;     // reg -> exu.

  logic [`CPU_WIDTH-1:0] exu_res;         // exu -> lsu/wbu.
  logic [`CPU_WIDTH-1:0] lsu_res;         // lsu -> wbu.

  logic zero;                             // exu -> pcu.
  logic brch,jal,jalr;                    // idu -> pcu.

  logic [`CPU_WIDTH-1:0] rd;              // wbu -> reg.  
  logic rdwen;                            // idu -> reg.

  logic a0zero;                           // use for sim, good trap or bad trap. if a0 is zero, a0zero == 1

  regfile u_regfile(
    .i_clk    (i_clk  ),
    .i_wen    (rdwen  ),
    .i_waddr  (rdid   ),
    .i_wdata  (rd     ),
    .i_raddr1 (rs1id  ),
    .i_raddr2 (rs2id  ),
    .o_rdata1 (rs1    ),
    .o_rdata2 (rs2    ),
    .s_a0zero (a0zero )
  );

  ifu u_ifu(
    .i_pc     (pc         ),
    .i_rst_n  (rst_n_sync ),
    .o_ins    (ins        )
  );

  idu u_idu(
    .i_ins         (ins         ),
    .i_rst_n       (rst_n_sync  ),
    .o_rdid        (rdid        ),
    .o_rs1id       (rs1id       ),
    .o_rs2id       (rs2id       ),
    .o_rdwen       (rdwen       ),
    .o_imm         (imm         ),
    .o_exu_src_sel (exu_src_sel ),
    .o_exu_opt     (exu_opt     ),
    .o_lsu_opt     (lsu_opt     ),
    .o_brch        (brch        ),
    .o_jal         (jal         ),
    .o_jalr        (jalr        )
  );

  exu u_exu(
    .i_pc      (pc          ),
    .i_rs1     (rs1         ),
    .i_rs2     (rs2         ),
    .i_imm     (imm         ),
    .i_src_sel (exu_src_sel ),
    .i_opt     (exu_opt     ),
    .o_exu_res (exu_res     ),
    .o_zero    (zero        )
  );

  lsu u_lsu(
    .i_clk   (i_clk       ),
    .i_rst_n (rst_n_sync  ),
    .i_opt   (lsu_opt     ),
    .i_addr  (exu_res     ),
    .i_regst (rs2         ),
    .o_regld (lsu_res     )
  );

  wbu u_wbu(
    .i_exu_res (exu_res     ),
    .i_lsu_res (lsu_res     ),
    .i_ld_en   (~lsu_opt[0] ),
    .o_rd      (rd          )
  );

  pcu u_pcu(
    .i_clk    (i_clk      ),
    .i_rst_n  (rst_n_sync ),
    .i_brch   (brch       ),
    .i_jal    (jal        ),
    .i_jalr   (jalr       ),
    .i_zero   (zero       ),
    .i_rs1    (rs1        ),
    .i_imm    (imm        ),
    .o_pc     (pc         )
  );

  //3.sim:  ////////////////////////////////////////////////////////
  import "DPI-C" function void check_rst(input bit rst_flag);
  import "DPI-C" function bit check_finsih(input int finish_flag);
  always@(*)begin
    check_rst(rst_n_sync);
    if(check_finsih(ins))begin  //ins == ebreak.
      $display("\n----------EBREAK: HIT !!%s!! TRAP!!---------------\n",a0zero? "GOOD":"BAD");
      $finish;
    end
  end

endmodule
