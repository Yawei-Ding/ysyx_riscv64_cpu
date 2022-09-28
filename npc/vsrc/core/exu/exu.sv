`include "defines.sv"
module exu (
  // 1. signal to pipe shake hands:
  input  logic                       i_clk         ,
  input  logic                       i_rst_n       ,
  input  logic                       i_flush       ,
  input  logic                       i_pre_nop     ,
  input  logic                       i_pre_valid   ,   // from pre-stage
  output logic                       o_pre_ready   ,   //  to  pre-stage
  output logic                       o_post_valid  ,   //  to  post-stage
  input  logic                       i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input  logic                       i_idu_sysins  ,
  // 2.1 use in exu.
  input  logic  [`CPU_WIDTH-1:0]     i_idu_imm     ,
  input  logic  [`CPU_WIDTH-1:0]     i_idu_csrs    ,
  input  logic  [`CPU_WIDTH-1:0]     i_idu_rs1     ,
  input  logic  [`CPU_WIDTH-1:0]     i_idu_rs2     ,
  input  logic  [`EXU_SEL_WIDTH-1:0] i_idu_exsrc   ,
  input  logic  [`EXU_OPT_WIDTH-1:0] i_idu_exopt   ,
  input  logic                       i_idu_excsrsrc,
  input  logic  [`CSR_OPT_WIDTH-1:0] i_idu_excsropt,
  // 2.2 dealy for lsu:
  input  logic  [2:0]                i_idu_lsfunc3 ,
  input  logic                       i_idu_lden    ,
  input  logic                       i_idu_sten    ,
  input  logic                       i_idu_fencei  ,
  // 2.3 dealy for wbu:
  input  logic  [`REG_ADDRW-1:0]     i_idu_rdid    ,
  input  logic                       i_idu_rdwen   ,
  input  logic  [`CSR_ADDRW-1:0]     i_idu_csrdid  ,
  input  logic                       i_idu_csrdwen , // csr dest write enable.
  // 2.4 dealy for bru/wbu:
  input  logic  [`CPU_WIDTH-1:0]     i_idu_pc      ,
  input  logic                       i_idu_ecall   ,
  input  logic                       i_idu_mret    ,
  input  logic                       i_idu_nop     ,
  input  logic  [`INS_WIDTH-1:0]     s_idu_ins     ,

  // 3. output comb signal to post stage:
  // 3.1 for lsu: 
  output logic  [`CPU_WIDTH-1:0]     o_exu_rs2     ,
  output logic  [2:0]                o_exu_lsfunc3 ,
  output logic                       o_exu_lden    ,
  output logic                       o_exu_sten    ,
  output logic                       o_exu_fencei  ,
  // 3.2 for lsu, dealy to use for wbu:
  output logic  [`REG_ADDRW-1:0]     o_exu_rdid    ,
  output logic                       o_exu_rdwen   ,
  output logic  [`CPU_WIDTH-1:0]     o_exu_res     ,
  output logic  [`CSR_ADDRW-1:0]     o_exu_csrdid  ,
  output logic                       o_exu_csrdwen , // csr dest write enable.
  output logic  [`CPU_WIDTH-1:0]     o_exu_csrd    ,
  output logic  [`CPU_WIDTH-1:0]     o_exu_pc      ,
  output logic                       o_exu_ecall   ,
  output logic                       o_exu_mret    ,
  output logic                       o_exu_nop     ,
  output logic  [`INS_WIDTH-1:0]     s_exu_ins
);

  // 1. shake hands://///////////////////////////////////////////////////////////////////////////////////////

  // for one cycle alu, such as + - >> <<:
  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  // for more cycles alu, such as / % :

  // i_pre_valid -->⌈‾‾‾‾⌉-->pre_valid_r -->div_start-->⌈‾‾‾‾⌉-->div_end_valid |  --> o_post_valid
  //                |REG|                        ↑     |DIV |                 |  
  // o_pre_ready <--⌊____⌋                   div_busy<--⌊____⌋<--div_end_ready |  <-- i_post_ready

  logic alu_int, alu_mul, alu_div;
  logic pre_valid_r, div_end_valid, div_end_ready;

  wire pre_sh;
  assign o_pre_ready = o_post_valid & i_post_ready | !pre_valid_r ;
  assign pre_sh = i_pre_valid & o_pre_ready;

  stl_reg #(
    .WIDTH      (1            ), 
    .RESET_VAL  (0            )
  ) postvalid ( 
  	.i_clk      (i_clk        ), 
    .i_rst_n    (i_rst_n      ), 
    .i_wen      (i_flush | o_pre_ready      ), 
    .i_din      (i_flush ? 1'b0: i_pre_valid), 
    .o_dout     (pre_valid_r  )
  );

  assign div_end_ready = alu_div ? i_post_ready : 1'b0;
  assign o_post_valid = alu_div ? div_end_valid : pre_valid_r;

 //  2. reg pre stage signals: ///////////////////////////////////////////////////////////////////////////////

  logic                        idu_sysins_r  ;
  logic  [`CPU_WIDTH-1:0]      idu_imm_r     ;
  logic  [`CPU_WIDTH-1:0]      idu_csrs_r    ;
  logic  [`CPU_WIDTH-1:0]      idu_rs1_r     ;
  logic  [`CPU_WIDTH-1:0]      idu_rs2_r     ;
  logic  [`EXU_SEL_WIDTH-1:0]  idu_exsrc_r   ;
  logic  [`EXU_OPT_WIDTH-1:0]  idu_exopt_r   ;
  logic                        idu_excsrsrc_r;
  logic  [`CSR_OPT_WIDTH-1:0]  idu_excsropt_r;
  logic  [2:0]                 idu_lsfunc3_r ;
  logic                        idu_lden_r    ;
  logic                        idu_sten_r    ;
  logic                        idu_fencei_r  ;
  logic  [`REG_ADDRW-1:0]      idu_rdid_r    ;
  logic                        idu_rdwen_r   ;
  logic  [`CSR_ADDRW-1:0]      idu_csrdid_r  ;
  logic                        idu_csrdwen_r ;
  logic  [`CPU_WIDTH-1:0]      idu_pc_r      ;
  logic  [`INS_WIDTH-1:0]      idu_ins_r     ;
  logic                        idu_ecall_r   ;
  logic                        idu_mret_r    ;
  logic                        idu_nop_r     ;

  parameter EXREG_WIDTH = 5*`CPU_WIDTH+`REG_ADDRW+13+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH+`CSR_OPT_WIDTH+`CSR_ADDRW+`INS_WIDTH;

  logic [EXREG_WIDTH-1:0] reg_din, reg_dout;

  assign reg_din = {i_flush | i_pre_nop ? {(EXREG_WIDTH-1){1'b0}} : {i_idu_sysins, i_idu_imm, i_idu_rs1, i_idu_rs2, i_idu_csrs, i_idu_exsrc, i_idu_exopt, i_idu_excsrsrc,
                     i_idu_excsropt, i_idu_lsfunc3, i_idu_lden, i_idu_sten, i_idu_fencei, i_idu_rdid, i_idu_rdwen, i_idu_csrdid, i_idu_csrdwen, i_idu_pc, i_idu_ecall, i_idu_mret, s_idu_ins},
                    i_flush ? 1'b0 : {i_pre_nop | i_idu_nop} };

  assign {idu_sysins_r, idu_imm_r, idu_rs1_r, idu_rs2_r, idu_csrs_r, idu_exsrc_r, idu_exopt_r, idu_excsrsrc_r, idu_excsropt_r, idu_lsfunc3_r,
          idu_lden_r, idu_sten_r, idu_fencei_r, idu_rdid_r, idu_rdwen_r, idu_csrdid_r, idu_csrdwen_r, idu_pc_r, idu_ecall_r, idu_mret_r, idu_ins_r, idu_nop_r} = reg_dout;

  stl_reg #(
    .WIDTH      (EXREG_WIDTH),
    .RESET_VAL  (0        )
  ) regs(
  	.i_clk      (i_clk    ),
    .i_rst_n    (i_rst_n  ),
    .i_wen      (i_flush | pre_sh  ),
    .i_din      (reg_din  ),
    .o_dout     (reg_dout )
  );

  // 3. use pre stage system signals to generate comb logic for post stage://////////////////////////////////////////

  logic [`CPU_WIDTH-1:0] sys_rs1, sys_csr, sys_csrres, sys_rdres;

  assign sys_rs1 = (idu_excsrsrc_r == `CSR_SEL_IMM) ? idu_imm_r : idu_rs1_r;
  assign sys_csr = idu_csrs_r;

  // cal sys_rdres :
  stl_mux_default #(1<<`CSR_OPT_WIDTH, `CSR_OPT_WIDTH, `CPU_WIDTH) mux_sys_rdres  (sys_rdres, idu_excsropt_r, `CPU_WIDTH'b0, {
    `CSR_NOP, `CPU_WIDTH'b0 ,
    `CSR_RW , sys_csr ,
    `CSR_RS , sys_csr ,
    `CSR_RC , sys_csr       
  });

  // cal sys_csrres :
  stl_mux_default #(1<<`CSR_OPT_WIDTH, `CSR_OPT_WIDTH, `CPU_WIDTH) mux_sys_csrres (sys_csrres, idu_excsropt_r, `CPU_WIDTH'b0, {
    `CSR_NOP, `CPU_WIDTH'b0       ,
    `CSR_RW ,             sys_rs1 ,
    `CSR_RS ,  sys_csr |  sys_rs1 ,
    `CSR_RC ,  sys_csr & ~sys_rs1   
  });

  // 4. use pre stage normal signals to generate comb logic for post stage://////////////////////////////////////////
  // 4.1 select src in and result: ///////////////////////////////////////////////////////////////////////////

  logic [`CPU_WIDTH-1:0] src1,src2;

  stl_mux_default #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src1 (src1, idu_exsrc_r, `CPU_WIDTH'b0, {
    `EXU_SEL_REG, idu_rs1_r,
    `EXU_SEL_IMM, idu_rs1_r,
    `EXU_SEL_PC4, idu_pc_r,
    `EXU_SEL_PCI, idu_pc_r
  });

  stl_mux_default #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src2 (src2, idu_exsrc_r, `CPU_WIDTH'b0, {
    `EXU_SEL_REG, idu_rs2_r,
    `EXU_SEL_IMM, idu_imm_r,
    `EXU_SEL_PC4, `CPU_WIDTH'h4,
    `EXU_SEL_PCI, idu_imm_r
  });

  // 请记住：硬件中不区分有符号和无符号，全部按照补码进行运算！
  // 所以 src1 - src2 得到是补码！ 如果src1和src2是有符号数，通过输出最高位就可以判断正负！
  // 如果src1和src2是无符号数，那么就在最高位补0，拓展为有符号数再减法，通过最高位判断正负！

  logic [`CPU_WIDTH-1:0] int_res, mul_res, div_res;

  // 4.2 generate integer alu result: ////////////////////////////////////////////////////////////////////////////////////////
  wire [63:0]   add_result  = src1 + src2;
  wire [63:0]   sub_result  = src1 - src2;
  wire [127:0]  sra_intern  = {{{64{src1[63]}},src1} >> src2[5:0]};
  wire [63:0]   sra_result  = sra_intern[63:0];
  wire [63:0]   slt_result  = {63'b0, sub_result[63]};
  wire [64:0]   sltu_intern = {1'b0,src1} - {1'b0,src2};
  wire [63:0]   sltu_result = {63'b0 , sltu_intern[64]};     

  always @(*) begin
    alu_int = 1'b1;
    case (idu_exopt_r)
      `EXU_ADD:   int_res = add_result;
      `EXU_SUB:   int_res = sub_result;
      `EXU_ADDW:  begin int_res[31:0] = src1[31:0] + src2[31:0];               int_res[63:32] = {32{int_res[31]}};  end
      `EXU_SUBW:  begin int_res[31:0] = src1[31:0] - src2[31:0];               int_res[63:32] = {32{int_res[31]}};  end
      `EXU_AND:   int_res = src1 & src2;
      `EXU_OR:    int_res = src1 | src2;
      `EXU_XOR:   int_res = src1 ^ src2;
      `EXU_SLL:   int_res = src1 << src2[5:0];
      `EXU_SRL:   int_res = src1 >> src2[5:0];
      `EXU_SRA:   int_res = sra_result;
      `EXU_SLLW:  begin int_res[31:0] = src1[31:0] << src2[4:0];               int_res[63:32] = {32{int_res[31]}};  end
      `EXU_SRLW:  begin int_res[31:0] = src1[31:0] >> src2[4:0];               int_res[63:32] = {32{int_res[31]}};  end
      `EXU_SRAW:  begin int_res = {{32{src1[31]}}, src1[31:0]} >> src2[4:0];   int_res[63:32] = {32{int_res[31]}};  end
      `EXU_SLT:   int_res = slt_result;
      `EXU_SLTU:  int_res = sltu_result;
      default:    begin int_res = `CPU_WIDTH'b0; alu_int = 1'b0; end
    endcase
  end

  // 4.3 generate multi alu result: ////////////////////////////////////////////////////////////////////////////////////////
  logic mulw, mul1_signed, mul2_signed;
  logic [`CPU_WIDTH-1:0] mul_src1, mul_src2, mul_hires, mul_lwres;
  
  assign mul_src1 = alu_mul ? src1 : `CPU_WIDTH'b0; // if not mul, close input to save power.
  assign mul_src2 = alu_mul ? src2 : `CPU_WIDTH'b0; // if not mul, close input to save power.

  mult #(.W(`CPU_WIDTH)) u_mult(
    .i_mulw   (mulw       ),
    .i_x_sign (mul1_signed),
    .i_y_sign (mul2_signed),
    .i_x      (mul_src1   ),
    .i_y      (mul_src2   ),
    .o_hi_res (mul_hires  ),
    .o_lw_res (mul_lwres  )
  );

  always @(*) begin
    case (idu_exopt_r)
      `EXU_MUL:   begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b1; mul2_signed = 1'b1;  mul_res = mul_lwres    ; end
      `EXU_MULH:  begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b1; mul2_signed = 1'b1;  mul_res = mul_hires    ; end
      `EXU_MULHSU:begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b1; mul2_signed = 1'b0;  mul_res = mul_hires    ; end
      `EXU_MULHU: begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b0; mul2_signed = 1'b0;  mul_res = mul_hires    ; end
      `EXU_MULW:  begin alu_mul  = 1'b1; mulw = 1'b1; mul1_signed = 1'b1; mul2_signed = 1'b1;  mul_res = mul_lwres    ; end
      default:    begin alu_mul  = 1'b0; mulw = 1'b0; mul1_signed = 1'b0; mul2_signed = 1'b0;  mul_res = `CPU_WIDTH'b0; end
    endcase
  end

  // 4.4 generate div alu result: ////////////////////////////////////////////////////////////////////////////////////////

  logic divw,div_signed;
  logic [`CPU_WIDTH-1:0] dividend, divisor, quotient, remainder;
  
  logic div_busy;
  wire div_start = (alu_div & pre_valid_r) & !div_busy;

  div #(.WIDTH (`CPU_WIDTH )) u_div(
    .i_clk          (i_clk         ),
    .i_rst_n        (i_rst_n       ),
    .i_flush        (i_flush       ),
    .i_divw         (divw          ),
    .i_start        (div_start     ),
    .o_busy         (div_busy      ),
    .o_end_valid    (div_end_valid ),
    .i_end_ready    (div_end_ready ),
    .i_signed       (div_signed    ),
    .i_dividend     (dividend      ),
    .i_divisor      (divisor       ),
    .o_quotient     (quotient      ),
    .o_remainder    (remainder     )
  );

  assign dividend = alu_div ? src1 : `CPU_WIDTH'b0; // if not div/rem, close input to save power.
  assign divisor  = alu_div ? src2 : `CPU_WIDTH'b0; // if not div/rem, close input to save power.

  always @(*) begin
    case (idu_exopt_r)
      `EXU_DIV:   begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b1; div_res = quotient     ; end
      `EXU_DIVU:  begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b0; div_res = quotient     ; end
      `EXU_DIVW:  begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b1; div_res = quotient     ; end
      `EXU_DIVUW: begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b0; div_res = quotient     ; end
      `EXU_REM:   begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b1; div_res = remainder    ; end
      `EXU_REMU:  begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b0; div_res = remainder    ; end
      `EXU_REMW:  begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b1; div_res = remainder    ; end
      `EXU_REMUW: begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b0; div_res = remainder    ; end
      default:    begin alu_div = 1'b0; divw = 1'b0; div_signed = 1'b0; div_res = `CPU_WIDTH'b0; end
    endcase
  end

  // 5. select output result: ////////////////////////////////////////////////////////////////////////////////////////

  assign o_exu_rs2     = idu_rs2_r    ;
  assign o_exu_lsfunc3 = idu_lsfunc3_r;
  assign o_exu_lden    = idu_lden_r   ;
  assign o_exu_sten    = idu_sten_r   ;
  assign o_exu_fencei  = idu_fencei_r ;
  assign o_exu_rdid    = idu_rdid_r   ;
  assign o_exu_rdwen   = idu_rdwen_r  ;
  assign o_exu_res     = idu_sysins_r ? sys_rdres :
                          (alu_div    ? div_res   :
                          (alu_mul    ? mul_res   :
                          (alu_int    ? int_res   : `CPU_WIDTH'b0)));
  assign o_exu_csrdid  = idu_csrdid_r ;
  assign o_exu_csrdwen = idu_csrdwen_r;
  assign o_exu_csrd    = sys_csrres   ;
  assign o_exu_pc      = idu_pc_r     ;
  assign o_exu_ecall   = idu_ecall_r  ;
  assign o_exu_mret    = idu_mret_r   ;
  assign o_exu_nop     = idu_nop_r    ;
  assign s_exu_ins     = idu_ins_r    ;

endmodule
