`include "config.sv"
module exu (
  // 1. signal to pipe shake hands:
  input                             i_clk         ,
  input                             i_rst_n       ,
  input                             i_pre_nop     ,
  input                             i_pre_valid   ,   // from pre-stage
  output                            o_pre_ready   ,   //  to  pre-stage
  output                            o_post_valid  ,   //  to  post-stage
  input                             i_post_ready  ,   // from post-stage

  // 2. input comb signal from pre stage:
  input     [`CPU_WIDTH-1:0]        i_idu_imm     ,
  input     [`CPU_WIDTH-1:0]        i_idu_rs1     ,
  input     [`CPU_WIDTH-1:0]        i_idu_rs2     ,
  input     [`REG_ADDRW-1:0]        i_idu_rdid    ,
  input                             i_idu_rdwen   ,
  input     [`EXU_SEL_WIDTH-1:0]    i_idu_exsrc   ,
  input     [`EXU_OPT_WIDTH-1:0]    i_idu_exopt   ,
  input     [2:0]                   i_idu_lsfunc3 ,
  input                             i_idu_lden    ,
  input                             i_idu_sten    ,
  input                             i_idu_ldstbp  ,
  input     [`CPU_WIDTH-1:0]        i_idu_pc      ,
  input     [`CPU_WIDTH-1:0]        s_idu_diffpc  ,
  
  // 3. output comb signal to post stage:
  // 3.1 exu output value:
  output    [`CPU_WIDTH-1:0]        o_exu_res     ,
  // 3.2 for lsu:
  output    [`CPU_WIDTH-1:0]        o_exu_rs2     ,
  output    [2:0]                   o_exu_lsfunc3 ,
  output                            o_exu_lden    ,
  output                            o_exu_sten    ,
  output                            o_exu_ldstbp  ,
  // 3.3 for wbu:
  output    [`REG_ADDRW-1:0]        o_exu_rdid    ,
  output                            o_exu_rdwen   ,
  // 4 for sim:
  output    [`CPU_WIDTH-1:0]        s_exu_diffpc
);

  // 1. shake hands://///////////////////////////////////////////////////////////////////////////////////////

  // for one cycle alu, such as + - >> <<:
  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  // for more cycles alu, such as / % :

  // i_pre_valid -->⌈‾‾‾‾⌉-->valid -->div_start-->⌈‾‾‾‾⌉-->div_end_valid |  --> o_post_valid
  //                |REG|                  ↑     |DIV |                 |  
  // o_pre_ready <--⌊____⌋             div_busy<--⌊____⌋<--div_end_ready |  <-- i_post_ready

  logic alu_int, alu_mul, alu_div;
  logic one_cycle_valid;
  logic div_end_valid, div_end_ready;

  wire pre_sh;
  assign o_pre_ready =  alu_div ? (div_end_valid & div_end_ready): (o_post_valid & i_post_ready | !o_post_valid) ;
  assign pre_sh = i_pre_valid & o_pre_ready;

  stl_reg #(
    .WIDTH      (1              ), 
    .RESET_VAL  (0              )
  ) postvalid ( 
  	.i_clk      (i_clk          ), 
    .i_rst_n    (i_rst_n        ), 
    .i_wen      (o_pre_ready    ), 
    .i_din      (i_pre_valid    ), 
    .o_dout     (one_cycle_valid)
  );

  assign div_end_ready = alu_div ? i_post_ready : 1'b0;
  assign o_post_valid = alu_div ? div_end_valid : one_cycle_valid;


 //  2. reg pre stage signals: ///////////////////////////////////////////////////////////////////////////////

  logic  [`CPU_WIDTH-1:0]      idu_imm     ,idu_imm_r     ;
  logic  [`CPU_WIDTH-1:0]      idu_rs1     ,idu_rs1_r     ;
  logic  [`CPU_WIDTH-1:0]      idu_rs2     ,idu_rs2_r     ;
  logic  [`REG_ADDRW-1:0]      idu_rdid    ,idu_rdid_r    ;
  logic                        idu_rdwen   ,idu_rdwen_r   ;
  logic  [`EXU_SEL_WIDTH-1:0]  idu_exsrc   ,idu_exsrc_r   ;
  logic  [`EXU_OPT_WIDTH-1:0]  idu_exopt   ,idu_exopt_r   ;
  logic  [2:0]                 idu_lsfunc3 ,idu_lsfunc3_r ;
  logic                        idu_lden    ,idu_lden_r    ;
  logic                        idu_sten    ,idu_sten_r    ;
  logic                        idu_ldstbp  ,idu_ldstbp_r  ;
  logic  [`CPU_WIDTH-1:0]      idu_pc      ,idu_pc_r      ;
  logic  [`CPU_WIDTH-1:0]      idu_diffpc  ,idu_diffpc_r  ;

  assign idu_imm     = i_pre_nop ? `CPU_WIDTH'b0 : i_idu_imm     ;
  assign idu_rs1     = i_pre_nop ? `CPU_WIDTH'b0 : i_idu_rs1     ;
  assign idu_rs2     = i_pre_nop ? `CPU_WIDTH'b0 : i_idu_rs2     ;
  assign idu_rdid    = i_pre_nop ? `REG_ADDRW'b0 : i_idu_rdid    ;
  assign idu_rdwen   = i_pre_nop ?  1'b0         : i_idu_rdwen   ;
  assign idu_exsrc   = i_pre_nop ? `EXU_SEL_IMM  : i_idu_exsrc   ;
  assign idu_exopt   = i_pre_nop ? `EXU_ADD      : i_idu_exopt   ;
  assign idu_lsfunc3 = i_idu_lsfunc3 ;
  assign idu_lden    = i_pre_nop ?  1'b0         : i_idu_lden    ;
  assign idu_sten    = i_pre_nop ?  1'b0         : i_idu_sten    ;
  assign idu_ldstbp  = i_pre_nop ?  1'b0         : i_idu_ldstbp  ;
  assign idu_pc      = i_idu_pc ;
  assign idu_diffpc  = i_pre_nop ? `CPU_WIDTH'b1 : s_idu_diffpc  ; // use for sim, diffpc == 1 means data nop.

  stl_reg #(
    .WIDTH      (5*`CPU_WIDTH+`REG_ADDRW+7+`EXU_SEL_WIDTH+`EXU_OPT_WIDTH),
    .RESET_VAL  (0       )
  ) regs(
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pre_sh  ),
    .i_din      ({idu_imm  , idu_rs1  , idu_rs2  , idu_rdid  , idu_rdwen  , idu_exsrc  , idu_exopt  , idu_lsfunc3  , idu_lden  , idu_sten  , idu_ldstbp  , idu_pc  , idu_diffpc  } ),
    .o_dout     ({idu_imm_r, idu_rs1_r, idu_rs2_r, idu_rdid_r, idu_rdwen_r, idu_exsrc_r, idu_exopt_r, idu_lsfunc3_r, idu_lden_r, idu_sten_r, idu_ldstbp_r, idu_pc_r, idu_diffpc_r} )
  );

  // 3. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////
  // 3.1 select src in and result: ///////////////////////////////////////////////////////////////////////////

  assign o_exu_rs2     = idu_rs2_r    ;
  assign o_exu_lsfunc3 = idu_lsfunc3_r;
  assign o_exu_lden    = idu_lden_r   ;
  assign o_exu_sten    = idu_sten_r   ;
  assign o_exu_ldstbp  = idu_ldstbp_r ;
  assign o_exu_rdid    = idu_rdid_r   ;
  assign o_exu_rdwen   = idu_rdwen_r  ;
  assign s_exu_diffpc  = idu_diffpc_r ;

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

  assign o_exu_res = alu_div ? div_res : (alu_mul ? mul_res : (alu_int ? int_res : `CPU_WIDTH'b0));

  // 3.2 generate integer alu result: ////////////////////////////////////////////////////////////////////////////////////////
  always @(*) begin
    alu_int = 1'b1;
    case (idu_exopt_r)
      `EXU_ADD:   int_res = src1 + src2;
      `EXU_SUB:   int_res = src1 - src2;
      `EXU_ADDW:  begin int_res[31:0] = src1[31:0] + src2[31:0];               int_res = {{32{int_res[31]}},int_res[31:0]};end
      `EXU_SUBW:  begin int_res[31:0] = src1[31:0] - src2[31:0];               int_res = {{32{int_res[31]}},int_res[31:0]};end
      `EXU_AND:   int_res = src1 & src2;
      `EXU_OR:    int_res = src1 | src2;
      `EXU_XOR:   int_res = src1 ^ src2;
      `EXU_SLL:   int_res = src1 << src2[5:0];
      `EXU_SRL:   int_res = src1 >> src2[5:0];
      `EXU_SRA:   int_res = {{{64{src1[63]}},src1} >> src2[5:0]}[63:0];
      `EXU_SLLW:  begin int_res[31:0] = src1[31:0] << src2[4:0];               int_res = {{32{int_res[31]}},int_res[31:0]}; end
      `EXU_SRLW:  begin int_res[31:0] = src1[31:0] >> src2[4:0];               int_res = {{32{int_res[31]}},int_res[31:0]}; end
      `EXU_SRAW:  begin int_res = {{32{src1[31]}}, src1[31:0]} >> src2[4:0];   int_res = {{32{int_res[31]}},int_res[31:0]}; end
      `EXU_SLT:   begin int_res = {63'b0 , {src1 - src2}[63] };                                                             end
      `EXU_SLTU:  begin int_res = {63'b0 , {{1'b0,src1} - {1'b0,src2}}[64] };                                               end
      default:    begin int_res = `CPU_WIDTH'b0; alu_int = 1'b0; end
    endcase
  end

  // 3.3 generate multi alu result: ////////////////////////////////////////////////////////////////////////////////////////
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
      `EXU_MUL:   begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b1; mul2_signed = 1'b1;  mul_res = mul_lwres;     end
      `EXU_MULH:  begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b1; mul2_signed = 1'b1;  mul_res = mul_hires;     end
      `EXU_MULHSU:begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b1; mul2_signed = 1'b0;  mul_res = mul_hires;     end
      `EXU_MULHU: begin alu_mul  = 1'b1; mulw = 1'b0; mul1_signed = 1'b0; mul2_signed = 1'b0;  mul_res = mul_hires;     end
      `EXU_MULW:  begin alu_mul  = 1'b1; mulw = 1'b1; mul1_signed = 1'b1; mul2_signed = 1'b1;  mul_res = mul_lwres;     end
      default:    begin alu_mul  = 1'b0; mulw = 1'b0; mul1_signed = 1'b0; mul2_signed = 1'b0;  mul_res = `CPU_WIDTH'b0; end
    endcase
  end

  // 3.4 generate div alu result: ////////////////////////////////////////////////////////////////////////////////////////

  logic divw,div_signed;
  logic [`CPU_WIDTH-1:0] dividend, divisor, quotient, remainder;
  
  logic div_busy;
  wire div_start = (alu_div & one_cycle_valid) & !div_busy;

  div #(.WIDTH (`CPU_WIDTH )) u_div(
    .i_clk          (i_clk         ),
    .i_rst_n        (i_rst_n       ),
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
      `EXU_DIV:   begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b1; div_res = quotient ;     end
      `EXU_DIVU:  begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b0; div_res = quotient ;     end
      `EXU_DIVW:  begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b1; div_res = quotient ;     end
      `EXU_DIVUW: begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b0; div_res = quotient ;     end
      `EXU_REM:   begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b1; div_res = remainder;     end
      `EXU_REMU:  begin alu_div = 1'b1; divw = 1'b0; div_signed = 1'b0; div_res = remainder;     end
      `EXU_REMW:  begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b1; div_res = remainder;     end
      `EXU_REMUW: begin alu_div = 1'b1; divw = 1'b1; div_signed = 1'b0; div_res = remainder;     end
      default:    begin alu_div = 1'b0; divw = 1'b0; div_signed = 1'b0; div_res = `CPU_WIDTH'b0; end
    endcase
  end

endmodule
