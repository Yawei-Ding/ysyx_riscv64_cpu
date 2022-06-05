module alu (
  input         [`CPU_WIDTH-1:0]      i_src1    ,
  input         [`CPU_WIDTH-1:0]      i_src2    ,
  input         [`EXU_OPT_WIDTH-1:0]  i_opt     ,
  output logic  [`CPU_WIDTH-1:0]      o_alu_res ,
  output logic                        o_sububit 
);

  always @(*) begin
    o_alu_res   = `CPU_WIDTH'b0;
    o_sububit  = 1'b0;
    case (i_opt)
        `ALU_ADD:   o_alu_res = i_src1 + i_src2;
        `ALU_SUB:   o_alu_res = i_src1 - i_src2;
        `ALU_ADDW:  begin o_alu_res[31:0] = i_src1[31:0] + i_src2[31:0]; o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]};end
        `ALU_SUBW:  begin o_alu_res[31:0] = i_src1[31:0] - i_src2[31:0]; o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]};end
        `ALU_AND:   o_alu_res = i_src1 & i_src2;
        `ALU_OR:    o_alu_res = i_src1 | i_src2;
        `ALU_XOR:   o_alu_res = i_src1 ^ i_src2;
        `ALU_SLL:   o_alu_res = i_src1 << i_src2[5:0];
        `ALU_SRL:   o_alu_res = i_src1 >> i_src2[5:0];
        `ALU_SRA:   o_alu_res = {{{64{i_src1[63]}},i_src1} >> i_src2[5:0]}[63:0];
        `ALU_SLLW:  begin o_alu_res[31:0] = i_src1[31:0] << i_src2[4:0];               o_alu_res = {{32{o_alu_res[31]}},o_alu_res[31:0]}; end
        `ALU_SRLW:  begin o_alu_res[31:0] = i_src1[31:0] >> i_src2[4:0];               o_alu_res = {{32{o_alu_res[31]}},o_alu_res[31:0]}; end
        `ALU_SRAW:  begin o_alu_res = {{32{i_src1[31]}}, i_src1[31:0]} >> i_src2[4:0]; o_alu_res = {{32{o_alu_res[31]}},o_alu_res[31:0]}; end
        `ALU_MUL:   o_alu_res = i_src1 * i_src2;
        `ALU_MULH:  o_alu_res = i_src1 * i_src2 >> 64;
        `ALU_MULHSU:o_alu_res = {{1'b0, i_src1} * i_src2 >> 64}[63:0];
        `ALU_MULHU: o_alu_res = {{1'b0, i_src1} * {1'b0, i_src2} >> 64}[63:0]; 
        `ALU_DIV:   o_alu_res = i_src1 / i_src2;
        `ALU_DIVU:  o_alu_res = {{1'b0, i_src1} / {1'b0, i_src2}}[63:0];
        `ALU_REM:   o_alu_res = i_src1 % i_src2;
        `ALU_REMU:  o_alu_res = {{1'b0, i_src1} % {1'b0, i_src2}}[63:0];
        `ALU_MULW:  begin o_alu_res[31:0] = {i_src1[31:0] * i_src2[31:0]}[31:0];             o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]}; end
        `ALU_DIVW:  begin o_alu_res[31:0] = {i_src1[31:0] / i_src2[31:0]};                   o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]}; end
        `ALU_DIVUW: begin o_alu_res[31:0] = {{1'b0,i_src1[31:0]}/{1'b0,i_src2[31:0]}}[31:0]; o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]}; end
        `ALU_REMW:  begin o_alu_res[31:0] = {i_src1[31:0] % i_src2[31:0]};                   o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]}; end
        `ALU_REMUW: begin o_alu_res[31:0] = {{1'b0,i_src1[31:0]}%{1'b0,i_src2[31:0]}}[31:0]; o_alu_res = {{32{o_alu_res[31]}}, o_alu_res[31:0]}; end
        `ALU_SUBU:  {o_sububit,o_alu_res} = {1'b0,i_src1} - {1'b0,i_src2};  // use for sltu,bltu,bgeu
        default: ;
    endcase
  end

endmodule
