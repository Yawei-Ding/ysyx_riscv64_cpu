module EXU (
  input [`CPU_WIDTH-1:0]      pc      ,
  input [`CPU_WIDTH-1:0]      rs1     ,
  input [`CPU_WIDTH-1:0]      rs2     ,
  input [`CPU_WIDTH-1:0]      imm     ,
  input [`ALU_SEL_WIDTH-1:0]  src_sel ,
  input [`ALU_OPT_WIDTH-1:0]  opt      
);

  wire [`CPU_WIDTH-1:0] src1,src2;
  always @(*) begin
    src1 = rs1;
    src2 = rs2;
    case (src_sel) 
      `ALU_SEL_SRC: begin src1 = rs1;   src2 = rs2;           end
      `ALU_SEL_IMM: begin src1 = rs1;   src2 = imm;           end
      `ALU_SEL_PC4: begin src1 = pc ;   src2 = `CPU_WIDTH'b4; end
      `ALU_SEL_PCI: begin src1 = pc ;   src2 = imm;           end
    endcase
  end

  always @(*) begin
    case (opt)
      : 
      default: 
    endcase
  end
    
endmodule