`include "config.sv"
module exu (
  input         [`CPU_WIDTH-1:0]      i_pc      ,
  input         [`CPU_WIDTH-1:0]      i_rs1     ,
  input         [`CPU_WIDTH-1:0]      i_rs2     ,
  input         [`CPU_WIDTH-1:0]      i_imm     ,
  input         [`EXU_SEL_WIDTH-1:0]  i_src_sel ,
  input         [`EXU_OPT_WIDTH-1:0]  i_opt     ,
  output logic  [`CPU_WIDTH-1:0]      o_exu_res ,
  output logic                        o_zero
);

  logic [`CPU_WIDTH-1:0] src1,src2;

  MuxKeyWithDefault #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src1 (src1, i_src_sel, `CPU_WIDTH'b0, {
    `EXU_SEL_REG, i_rs1,
    `EXU_SEL_IMM, i_rs1,
    `EXU_SEL_PC4, i_pc,
    `EXU_SEL_PCI, i_pc
  });

  MuxKeyWithDefault #(1<<`EXU_SEL_WIDTH, `EXU_SEL_WIDTH, `CPU_WIDTH) mux_src2 (src2, i_src_sel, `CPU_WIDTH'b0, {
    `EXU_SEL_REG, i_rs2,
    `EXU_SEL_IMM, i_imm,
    `EXU_SEL_PC4, `CPU_WIDTH'h4,
    `EXU_SEL_PCI, i_imm
});

  // 请记住：硬件中不区分有符号和无符号，全部按照补码进行运算！
  // 所以 src1 - src2 得到是补码！ 如果src1和src2是有符号数，通过输出最高位就可以判断正负！
  // 如果src1和src2是无符号数，那么就在最高位补0，拓展为有符号数再减法，通过最高位判断正负！
  logic [`EXU_OPT_WIDTH-1:0]  alu_opt;
  logic [`CPU_WIDTH-1:0]      alu_res;
  logic                       sububit; // use for sltu,bltu,bgeu

  always @(*) begin
    case (i_opt)
      `EXU_SLT:   begin alu_opt = `ALU_SUB;   o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] = alu_res[`CPU_WIDTH-1] ;  end
      `EXU_SLTU:  begin alu_opt = `ALU_SUBU;  o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] = sububit               ;  end
      `EXU_BEQ:   begin alu_opt = `ALU_SUB;   o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] = ~(|alu_res)           ;  end
      `EXU_BNE:   begin alu_opt = `ALU_SUB;   o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] =  (|alu_res)           ;  end
      `EXU_BLT:   begin alu_opt = `ALU_SUB;   o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] =  alu_res[`CPU_WIDTH-1];  end
      `EXU_BGE:   begin alu_opt = `ALU_SUB;   o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] = ~alu_res[`CPU_WIDTH-1];  end
      `EXU_BLTU:  begin alu_opt = `ALU_SUBU;  o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] = sububit               ;  end
      `EXU_BGEU:  begin alu_opt = `ALU_SUBU;  o_exu_res[`CPU_WIDTH-1:1] = 0; o_exu_res[0] = ~sububit              ;  end
      default:    begin alu_opt = i_opt;      o_exu_res = alu_res;                                                   end
    endcase
  end

  alu u_alu(
    .i_src1    (src1      ),
    .i_src2    (src2      ),
    .i_opt     (alu_opt   ),
    .o_alu_res (alu_res   ),
    .o_sububit (sububit   )
  );

  assign o_zero = ~(|o_exu_res);

endmodule
