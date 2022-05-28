`include "vsrc/lib/define.sv"
module top(
  input                 clk   ,
  input                 rst_n ,
  input         [31:0]  ins   ,
  output logic  [63:0]  pc             
);
  //1.rst : ////////////////////////////////////////////////////////
  logic rst_n_sync;//rst_n for whole cpu!!
  rst u_rst(
  	.clk        (clk        ),
    .rst_n      (rst_n      ),
    .rst_n_sync (rst_n_sync )
  );

  //2.cpu:  /////////////////////////////////////////////////
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

  regfile u_regfile(
  	.clk    (clk    ),
    .wen    (rdwen  ),
    .waddr  (rdid   ),
    .wdata  (rd     ),
    .raddr1 (rs1id  ),
    .raddr2 (rs2id  ),
    .rdata1 (rs1    ),
    .rdata2 (rs2    )
  );
  
  idu u_idu(
  	.ins         (ins         ),
    .rdid        (rdid        ),
    .rs1id       (rs1id       ),
    .rs2id       (rs2id       ),
    .imm         (imm         ),
    .rdwen       (rdwen       ),
    .exu_src_sel (exu_src_sel ),
    .exu_opt     (exu_opt     ),
    .lsu_opt     (lsu_opt     ),
    .brch        (brch        ),
    .jal         (jal         ),
    .jalr        (jalr        )
  );
  
  exu u_exu(
    .pc      (pc          ),
    .rs1     (rs1         ),
    .rs2     (rs2         ),
    .imm     (imm         ),
    .src_sel (exu_src_sel ),
    .opt     (exu_opt     ),
    .result  (rd          ),
    .zero    (zero        )
  );

  lsu u_lsu(
    .clk    (clk      ),
    .opt    (lsu_opt  ),
    .addr   (exu_res  ),
    .regst  (rs2      ),
    .regld  (lsu_res  )
  );

  wbu u_wbu(
    .exu_res (exu_res     ),
    .lsu_res (lsu_res     ),
    .load_en (~lsu_opt[0] ),
    .rd      (rd          )
  );

  pcu u_pcu(
    .clk   (clk       ),
    .rst_n (rst_n_sync),
    .brch  (brch      ),
    .jal   (jal       ),
    .jalr  (jalr      ),
    .zero  (zero      ),
    .rs1   (rs1       ),
    .imm   (imm       ),
    .pc    (pc        )
  );

  //sim:  ////////////////////////////////////////////////////////
  import "DPI-C" function bit check_finsih(input int finish_flag);
  always@(*)begin
    if(check_finsih(ins))begin
      $finish;
      $display("HIT GOOD TRAP!!");
    end
  end

endmodule
