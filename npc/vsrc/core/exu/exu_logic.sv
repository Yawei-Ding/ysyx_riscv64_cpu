`include "config.sv"
module exu_logic (
  input         [`CPU_WIDTH-1:0]      i_pc      ,
  input         [`CPU_WIDTH-1:0]      i_rs1     ,
  input         [`CPU_WIDTH-1:0]      i_rs2     ,
  input         [`CPU_WIDTH-1:0]      i_imm     ,
  input         [`EXU_SEL_WIDTH-1:0]  i_exsrc   ,
  input         [`EXU_OPT_WIDTH-1:0]  i_exopt   ,
  output logic  [`CPU_WIDTH-1:0]      o_exu_res
);

  logic [`CPU_WIDTH-1:0] src1,src2;

  stl_mux_default #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src1 (src1, i_exsrc, `CPU_WIDTH'b0, {
    `EXU_SEL_REG, i_rs1,
    `EXU_SEL_IMM, i_rs1,
    `EXU_SEL_PC4, i_pc,
    `EXU_SEL_PCI, i_pc
  });

  stl_mux_default #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src2 (src2, i_exsrc, `CPU_WIDTH'b0, {
    `EXU_SEL_REG, i_rs2,
    `EXU_SEL_IMM, i_imm,
    `EXU_SEL_PC4, `CPU_WIDTH'h4,
    `EXU_SEL_PCI, i_imm
});

  // 请记住：硬件中不区分有符号和无符号，全部按照补码进行运算！
  // 所以 src1 - src2 得到是补码！ 如果src1和src2是有符号数，通过输出最高位就可以判断正负！
  // 如果src1和src2是无符号数，那么就在最高位补0，拓展为有符号数再减法，通过最高位判断正负！

  logic src1_signed, src2_signed;
  logic [`CPU_WIDTH-1:0] mul_src1, mul_src2, mul_hires, mul_lwres;
  
  mult #(.W(`CPU_WIDTH)) u_mult(
    .i_x_sign (src1_signed),
    .i_y_sign (src2_signed),
    .i_x      (mul_src1   ),
    .i_y      (mul_src2   ),
    .o_hi_res (mul_hires  ),
    .o_lw_res (mul_lwres  )
  );

  always @(*) begin
    src1_signed = 1'b0;
    src2_signed = 1'b0;
    mul_src1 = `CPU_WIDTH'b0;
    mul_src2 = `CPU_WIDTH'b0;
    case (i_exopt)
      `EXU_ADD:   o_exu_res = src1 + src2;
      `EXU_SUB:   o_exu_res = src1 - src2;
      `EXU_ADDW:  begin o_exu_res[31:0] = src1[31:0] + src2[31:0]; o_exu_res = {{32{o_exu_res[31]}}, o_exu_res[31:0]};end
      `EXU_SUBW:  begin o_exu_res[31:0] = src1[31:0] - src2[31:0]; o_exu_res = {{32{o_exu_res[31]}}, o_exu_res[31:0]};end
      `EXU_AND:   o_exu_res = src1 & src2;
      `EXU_OR:    o_exu_res = src1 | src2;
      `EXU_XOR:   o_exu_res = src1 ^ src2;
      `EXU_SLL:   o_exu_res = src1 << src2[5:0];
      `EXU_SRL:   o_exu_res = src1 >> src2[5:0];
      `EXU_SRA:   o_exu_res = {{{64{src1[63]}},src1} >> src2[5:0]}[63:0];
      `EXU_SLLW:  begin o_exu_res[31:0] = src1[31:0] << src2[4:0];               o_exu_res = {{32{o_exu_res[31]}},o_exu_res[31:0]}; end
      `EXU_SRLW:  begin o_exu_res[31:0] = src1[31:0] >> src2[4:0];               o_exu_res = {{32{o_exu_res[31]}},o_exu_res[31:0]}; end
      `EXU_SRAW:  begin o_exu_res = {{32{src1[31]}}, src1[31:0]} >> src2[4:0];   o_exu_res = {{32{o_exu_res[31]}},o_exu_res[31:0]}; end
      // mult:
      `EXU_MUL:   begin src1_signed = 1'b1; src2_signed = 1'b1; mul_src1 = src1;  mul_src2 = src2;  o_exu_res = mul_lwres;  end
      `EXU_MULH:  begin src1_signed = 1'b1; src2_signed = 1'b1; mul_src1 = src1;  mul_src2 = src2;  o_exu_res = mul_hires;  end
      `EXU_MULHSU:begin src1_signed = 1'b1; src2_signed = 1'b0; mul_src1 = src1;  mul_src2 = src2;  o_exu_res = mul_hires;  end
      `EXU_MULHU: begin src1_signed = 1'b0; src2_signed = 1'b0; mul_src1 = src1;  mul_src2 = src2;  o_exu_res = mul_hires;  end
      `EXU_MULW:  begin src1_signed = 1'b1; src2_signed = 1'b1; mul_src1 = {{32{src1[31]}},src1[31:0]};;  mul_src2 = {{32{src2[31]}},src2[31:0]};  o_exu_res = mul_lwres; end
      // div:
      `EXU_DIV:   o_exu_res = src1 / src2;
      `EXU_DIVU:  o_exu_res = {{1'b0, src1} / {1'b0, src2}}[63:0];
      `EXU_DIVW:  begin o_exu_res[31:0] = {src1[31:0] / src2[31:0]};                   o_exu_res = {{32{o_exu_res[31]}}, o_exu_res[31:0]}; end
      `EXU_DIVUW: begin o_exu_res[31:0] = {{1'b0,src1[31:0]}/{1'b0,src2[31:0]}}[31:0]; o_exu_res = {{32{o_exu_res[31]}}, o_exu_res[31:0]}; end
      // rem:
      `EXU_REM:   o_exu_res = src1 % src2;
      `EXU_REMU:  o_exu_res = {{1'b0, src1} % {1'b0, src2}}[63:0];
      `EXU_REMW:  begin o_exu_res[31:0] = {src1[31:0] % src2[31:0]};                   o_exu_res = {{32{o_exu_res[31]}}, o_exu_res[31:0]}; end
      `EXU_REMUW: begin o_exu_res[31:0] = {{1'b0,src1[31:0]}%{1'b0,src2[31:0]}}[31:0]; o_exu_res = {{32{o_exu_res[31]}}, o_exu_res[31:0]}; end
      `EXU_SLT:   begin o_exu_res = {63'b0 , {src1 - src2}[63] };                                                                          end
      `EXU_SLTU:  begin o_exu_res = {63'b0 , {{1'b0,src1} - {1'b0,src2}}[64] };                                                            end
      default:    o_exu_res = `CPU_WIDTH'b0;
    endcase
  end

endmodule
