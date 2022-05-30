`include "vsrc/lib/define.sv"
module exu (
  input         [`CPU_WIDTH-1:0]      pc      ,
  input         [`CPU_WIDTH-1:0]      rs1     ,
  input         [`CPU_WIDTH-1:0]      rs2     ,
  input         [`CPU_WIDTH-1:0]      imm     ,
  input         [`EXU_SEL_WIDTH-1:0]  src_sel ,
  input         [`EXU_OPT_WIDTH-1:0]  opt     ,
  output logic  [`CPU_WIDTH-1:0]      result  ,
  output logic                        zero
); 
  assign zero = ~(|result);
  logic [`CPU_WIDTH-1:0] src1,src2;
  always @(*) begin
    src1 = rs1; src2 = rs2;
    case (src_sel) 
      `EXU_SEL_REG: begin src1 = rs1;   src2 = rs2;           end
      `EXU_SEL_IMM: begin src1 = rs1;   src2 = imm;           end
      `EXU_SEL_PC4: begin src1 = pc ;   src2 = `CPU_WIDTH'h4; end
      `EXU_SEL_PCI: begin src1 = pc ;   src2 = imm;           end
    endcase
  end

  // 请记住：硬件中不区分有符号和无符号，全部按照补码进行运算！
  // 所以 src1 - src2 得到是补码！ 如果src1和src2是有符号数，通过输出最高位就可以判断正负！
  // 如果src1和src2是无符号数，那么就在最高位补0，拓展为有符号数再减法，通过最高位判断正负！
  logic [`EXU_OPT_WIDTH-1:0]  alu_opt;
  logic [`CPU_WIDTH-1:0]      alu_res;
  logic                       sububit; // use for sltu,bltu,bgeu
  always @(*) begin
    case (opt)
      `EXU_SLT:   begin alu_opt = `ALU_SUB;   result[`CPU_WIDTH-1:1] = 0; result[0] = alu_res[`CPU_WIDTH-1] ;  end
      `EXU_SLTU:  begin alu_opt = `ALU_SUBU;  result[`CPU_WIDTH-1:1] = 0; result[0] = sububit               ;  end
      `EXU_BEQ:   begin alu_opt = `ALU_SUB;   result[`CPU_WIDTH-1:1] = 0; result[0] = ~(|alu_res)           ;  end
      `EXU_BNE:   begin alu_opt = `ALU_SUB;   result[`CPU_WIDTH-1:1] = 0; result[0] =  (|alu_res)           ;  end
      `EXU_BLT:   begin alu_opt = `ALU_SUB;   result[`CPU_WIDTH-1:1] = 0; result[0] =  alu_res[`CPU_WIDTH-1];  end
      `EXU_BGE:   begin alu_opt = `ALU_SUB;   result[`CPU_WIDTH-1:1] = 0; result[0] = ~alu_res[`CPU_WIDTH-1];  end
      `EXU_BLTU:  begin alu_opt = `ALU_SUBU;  result[`CPU_WIDTH-1:1] = 0; result[0] = sububit               ;  end
      `EXU_BGEU:  begin alu_opt = `ALU_SUBU;  result[`CPU_WIDTH-1:1] = 0; result[0] = sububit               ;  end
      default:    begin alu_opt = opt;        result = alu_res;                                                end
    endcase
  end

  alu u_alu(
    .src1     (src1   ),
    .src2     (src2   ),
    .opt      (alu_opt),
    .result   (alu_res),
    .sububit  (sububit)
  );
    
endmodule
