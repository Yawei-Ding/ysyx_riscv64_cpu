`include "define.sv"
module IDU(
  input        [31:0]               ins,
  output logic                      rdwen,
  output logic [`REG_ADDRW-1:0]     rdid ,
  output logic [`REG_ADDRW-1:0]     rs1id,
  output logic [`REG_ADDRW-1:0]     rs2id,
  output logic [`CPU_WIDTH-1:0]     imm  ,
  output logic [ALU_OPT_WIDTH-1:0]  ALU_opt,
  output logic [ALU_SEL_WIDTH-1:0]  ALU_src_sel,
  output logic                      brch,
  output logic                      jal ,
  output logic                      jalr
);

  // ebreak & ecall are not supperted now. ebreak will cause system finish.
  wire [6:0] func7  = ins[31:25];
  wire [4:0] rs2    = ins[24:20];
  wire [4:0] rs1    = ins[19:15];
  wire [2:0] func3  = ins[14:12];
  wire [4:0] rd     = ins[11: 7];
  wire [6:0] opcode = ins[ 6: 0];

  //1.reg info:  ////////////////////////////////////////////////////////////////////
  always@(*)begin
    rs2id = `REG_ADDRW'b0;
    rs1id = `REG_ADDRW'b0;
    rdid  = `REG_ADDRW'b0; 
    rdwen = 1'b0;
    case(opcode) 
      `TYPE_R:        begin rs2id = rs2;  rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      `TYPE_R_W:      begin rs2id = rs2;  rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      `TYPE_S:        begin rs2id = rs2;  rs1id = rs1;                            end
      `TYPE_B:        begin rs2id = rs2;  rs1id = rs1;                            end
      `TYPE_I:        begin               rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      `TYPE_I_W:      begin               rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      `TYPE_I_LOAD:   begin               rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      `TYPE_I_JALR:   begin               rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      //`TYPE_I_EBRK:   begin               rs1id = rs1;  rdid = rd;  rdwen = 1'b1; end
      `TYPE_U_LUI:    begin               rs1id = 0  ;  rdid = rd;  rdwen = 1'b1; end //LUI: rd = x0 + imm;
      `TYPE_U_AUIPC:  begin                             rdid = rd;  rdwen = 1'b1; end
      `TYPE_J:        begin                             rdid = rd;  rdwen = 1'b1; end
    endcase
  end

  //2.imm info:  ////////////////////////////////////////////////////////////////////
  always@(*)begin
    imm = `CPU_WIDTH'b0;
    case (opcode)
      `TYPE_R:        imm = `CPU_WIDTH'b0;
      `TYPE_R_W:      imm = `CPU_WIDTH'b0;
      `TYPE_S:        imm = {{52{ins[31]}},ins[31:25],ins[11:7]};
      `TYPE_B:        imm = {{52{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0};
      `TYPE_I_W:      imm = {59'b0,ins[24:20]}; 
      `TYPE_I_LOAD:   imm = {{52{ins[31]}},ins[31:20]};
      `TYPE_I_JALR:   imm = {{52{ins[31]}},ins[31:20]};
      //`TYPE_I_EBRK:   imm = {{52{ins[31]}},ins[31:20]};
      `TYPE_U_LUI:    imm = {{32{ins[31]}},ins[31:12],12'b0};
      `TYPE_U_AUIPC:  imm = {{32{ins[31]}},ins[31:12],12'b0};
      `TYPE_J:        imm = {{44{ins[31]}},ins[19:12],ins[20],ins[30:21],1'b0};
      `TYPE_I:
        case (func3)
          FUNC3_SLL:      imm = {58'b0,ins[25:20]};
          FUNC3_SRL_SRA:  imm = {58'b0,ins[25:20]};
          default:        imm = {{52{ins[31]}},ins[31:20]};
        endcase
    endcase
  end

  //3.alu info:  ////////////////////////////////////////////////////////////////////
  always @(*) begin
    ALU_opt     = `ALU_ADD;
    ALU_src_sel = `ALU_SEL_IMM;
    case (opcode)
      `TYPE_S:        begin ALU_opt = `ALU_ADD;  ALU_src_sel = `ALU_SEL_IMM; end // M[rs1+imm] = rs2
      //`TYPE_I_EBRK:   begin end
      `TYPE_I_LOAD:   begin ALU_opt = `ALU_ADD;  ALU_src_sel = `ALU_SEL_IMM; end // rd = M[rs1+imm]
      `TYPE_I_JALR:   begin ALU_opt = `ALU_ADD;  ALU_src_sel = `ALU_SEL_PC4; end // rd = PC+4
      `TYPE_J:        begin ALU_opt = `ALU_ADD;  ALU_src_sel = `ALU_SEL_PC4; end // rd = PC+4
      `TYPE_U_LUI:    begin ALU_opt = `ALU_ADD;  ALU_src_sel = `ALU_SEL_IMM; end // rd = x0 + imm
      `TYPE_U_AUIPC:  begin ALU_opt = `ALU_ADD;  ALU_src_sel = `ALU_SEL_PCI; end // rd = pc + imm
      `TYPE_B:        begin ALU_opt = `ALU_SUB;  ALU_src_sel = `ALU_SEL_REG; end // judge rs1 and rs2, use SUB!!
      `TYPE_R: begin
        ALU_src_sel = `ALU_SEL_REG;
        case (func3)
          `FUNC3_ADD_SUB: if(func7 == 7'h00) ALU_opt = `ALU_ADD; else ALU_opt = `ALU_SUB;
          `FUNC3_SRL_SRA: if(func7 == 7'h00) ALU_opt = `ALU_SRL; else ALU_opt = `ALU_SRA;
          `FUNC3_SLL:     ALU_opt = `ALU_SLL;
          `FUNC3_XOR:     ALU_opt = `ALU_XOR;
          `FUNC3_OR:      ALU_opt = `ALU_OR ;
          `FUNC3_AND:     ALU_opt = `ALU_AND;
          `FUNC3_SLT:     ALU_opt = `ALU_SLT;
          `FUNC3_SLTU:    ALU_opt = `ALU_SLTU;
        endcase
      end
      `TYPE_I:begin
        ALU_src_sel = `ALU_SEL_IMM;
        case (func3)
          `FUNC3_ADD_SUB: ALU_opt = `ALU_ADD;
          `FUNC3_SRL_SRA: if(func7 == 7'h00) ALU_opt = `ALU_SRL; else ALU_opt = `ALU_SRA;
          `FUNC3_SLL:     ALU_opt = `ALU_SLL;
          `FUNC3_XOR:     ALU_opt = `ALU_XOR;
          `FUNC3_OR:      ALU_opt = `ALU_OR ;
          `FUNC3_AND:     ALU_opt = `ALU_AND;
          `FUNC3_SLT:     ALU_opt = `ALU_SLT;
          `FUNC3_SLTU:    ALU_opt = `ALU_SLTU;
        endcase
      end
      `TYPE_I_W: begin
        ALU_src_sel = `ALU_SEL_IMM;
        case (func3)
          `FUNC3_ADD_SUB: ALU_opt = `ALU_ADDW;
          `FUNC3_SRL_SRA: if(func7 == 7'h00) ALU_opt = `ALU_SRLW; else ALU_opt = `ALU_SRAW;
          `FUNC3_SLL:     ALU_opt = `ALU_SLLW;
        endcase
      end
      `TYPE_R_W: begin
        ALU_src_sel = `ALU_SEL_REG;
        case (func3)
          `FUNC3_ADD_SUB: if(func7 == 7'h00) ALU_opt = `ALU_ADDW; else ALU_opt = `ALU_SUBW;
          `FUNC3_SRL_SRA: if(func7 == 7'h00) ALU_opt = `ALU_SRLW; else ALU_opt = `ALU_SRAW;
          `FUNC3_SLL:     ALU_opt = `ALU_SLLW;
        endcase
      end 
    endcase
  end

  // 4.branch,jal,jalr:  ////////////////////////////////////////////////////////////////////
  always@(*)begin
    brch = 1'b0;
    jal  = 1'b0;
    jalr = 1'b0;
    case (opcode)
      `TYPE_J:      jal  = 1'b1;
      `TYPE_I_JALR: jalr = 1'b1;
      `TYPE_B:      brch = 1'b1;
    endcase
  end

endmodule
