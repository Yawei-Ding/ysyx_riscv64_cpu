module alu (
  input         [`CPU_WIDTH-1:0]      src1    ,
  input         [`CPU_WIDTH-1:0]      src2    ,
  input         [`EXU_OPT_WIDTH-1:0]  opt     ,
  output logic  [`CPU_WIDTH-1:0]      result  ,
  output logic                        sububit 
); 
  // logic [HALF_WIDTH-1:0] half_res;
  logic [31:0] half_res;

  always @(*) begin
    result   = `CPU_WIDTH'b0;
    // half_res = `HALF_WIDTH'b0;
    half_res = 32'b0;
    sububit  = 1'b0;
    case (opt)
        `ALU_ADD:   result = src1 + src2;
        `ALU_SUB:   result = src1 - src2;
        // `ALU_ADDW:  begin half_res = src1[31:0] + src2[31:0]; result = {{`HALF_WIDTH{half_res[`HALF_WIDTH-1]}}, half_res};end
        // `ALU_SUBW:  begin half_res = src1[31:0] - src2[31:0]; result = {{`HALF_WIDTH{half_res[`HALF_WIDTH-1]}}, half_res};end
        `ALU_ADDW:  begin half_res = src1[31:0] + src2[31:0]; result = {{32{half_res[31]}}, half_res};end
        `ALU_SUBW:  begin half_res = src1[31:0] - src2[31:0]; result = {{32{half_res[31]}}, half_res};end
        `ALU_AND:   result = src1 & src2;
        `ALU_OR:    result = src1 | src2;
        `ALU_XOR:   result = src1 ^ src2;
        `ALU_SLL:   result = src1 <<  src2[5:0];
        `ALU_SRL:   result = src1 >>  src2[5:0];
        `ALU_SRA:   result = src1 >>> src2[5:0];
        // `ALU_SLLW:  begin half_res = src1[31:0] <<  src2[4:0]; result = {{`HALF_WIDTH{half_res[`HALF_WIDTH-1]}}, half_res};end
        // `ALU_SRLW:  begin half_res = src1[31:0] >>  src2[4:0]; result = {{`HALF_WIDTH{half_res[`HALF_WIDTH-1]}}, half_res};end
        // `ALU_SRAW:  begin half_res = src1[31:0] >>> src2[4:0]; result = {{`HALF_WIDTH{half_res[`HALF_WIDTH-1]}}, half_res};end
        `ALU_SLLW:  begin half_res = src1[31:0] <<  src2[4:0]; result = {{32{half_res[31]}}, half_res};end
        `ALU_SRLW:  begin half_res = src1[31:0] >>  src2[4:0]; result = {{32{half_res[31]}}, half_res};end
        `ALU_SRAW:  begin half_res = src1[31:0] >>> src2[4:0]; result = {{32{half_res[31]}}, half_res};end
        `ALU_SUBU:  {sububit,result} = {1'b0,src1} - {1'b0,src2};  // use for sltu,bltu,bgeu
        default: ;
    endcase
  end

endmodule
