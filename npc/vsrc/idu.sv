`include "vsrc/lib/define.sv"
module idu(
  input        [31:0]               ins,
  output logic [`REG_ADDRW-1:0]     rdid ,
  output logic [`REG_ADDRW-1:0]     rs1id,
  output logic [`REG_ADDRW-1:0]     rs2id,
  output logic [`CPU_WIDTH-1:0]     imm  ,
  
  // output flags:
  output logic                      rdwen,      //for reg.
  output logic [`EXU_SEL_WIDTH-1:0] exu_src_sel,//for exu.
  output logic [`EXU_OPT_WIDTH-1:0] exu_opt,    //for exu.
  output logic [`LSU_OPT_WIDTH-1:0] lsu_opt,    //for lsu.
  output logic                      brch,       //for pcu.
  output logic                      jal ,       //for pcu.
  output logic                      jalr        //for pcu.
);

  // ebreak & ecall are not supperted now. ebreak will cause system finish.
  //wire [6:0] func7  = ins[31:25]; // no use, warning.
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
      `TYPE_I_EBRK:   begin               rs1id = rs1;  rdid = rd;                end
      `TYPE_U_LUI:    begin               rs1id = 0  ;  rdid = rd;  rdwen = 1'b1; end //LUI: rd = x0 + imm;
      `TYPE_U_AUIPC:  begin                             rdid = rd;  rdwen = 1'b1; end
      `TYPE_J:        begin                             rdid = rd;  rdwen = 1'b1; end
      default:  ;
    endcase
  end

  //2.imm info:  ////////////////////////////////////////////////////////////////////
  always@(*)begin
    case (opcode)
      `TYPE_R:        imm = `CPU_WIDTH'b0;
      `TYPE_R_W:      imm = `CPU_WIDTH'b0;
      `TYPE_S:        imm = {{52{ins[31]}},ins[31:25],ins[11:7]};
      `TYPE_B:        imm = {{52{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0};
      `TYPE_I_W:      imm = {{52{ins[31]}},ins[31:20]};
      `TYPE_I_LOAD:   imm = {{52{ins[31]}},ins[31:20]};
      `TYPE_I_JALR:   imm = {{52{ins[31]}},ins[31:20]};
      `TYPE_I_EBRK:   imm = {{52{ins[31]}},ins[31:20]};
      `TYPE_U_LUI:    imm = {{32{ins[31]}},ins[31:12],12'b0};
      `TYPE_U_AUIPC:  imm = {{32{ins[31]}},ins[31:12],12'b0};
      `TYPE_J:        imm = {{44{ins[31]}},ins[19:12],ins[20],ins[30:21],1'b0};
      `TYPE_I:        imm = {{52{ins[31]}},ins[31:20]};
      default:        imm = `CPU_WIDTH'b0;
    endcase
  end

  //3.alu info:  ////////////////////////////////////////////////////////////////////
  always @(*) begin
    exu_opt     = `EXU_ADD;
    exu_src_sel = `EXU_SEL_IMM;
    case (opcode)
      `TYPE_S:        begin exu_opt = `EXU_ADD;  exu_src_sel = `EXU_SEL_IMM; end // M[rs1+imm] = rs2
      `TYPE_I_EBRK:   begin                                                  end // no use, dirct break.
      `TYPE_I_LOAD:   begin exu_opt = `EXU_ADD;  exu_src_sel = `EXU_SEL_IMM; end // rd = M[rs1+imm]
      `TYPE_I_JALR:   begin exu_opt = `EXU_ADD;  exu_src_sel = `EXU_SEL_PC4; end // rd = PC+4
      `TYPE_J:        begin exu_opt = `EXU_ADD;  exu_src_sel = `EXU_SEL_PC4; end // rd = PC+4
      `TYPE_U_LUI:    begin exu_opt = `EXU_ADD;  exu_src_sel = `EXU_SEL_IMM; end // rd = x0 + imm
      `TYPE_U_AUIPC:  begin exu_opt = `EXU_ADD;  exu_src_sel = `EXU_SEL_PCI; end // rd = pc + imm
      `TYPE_B: begin
        exu_src_sel = `EXU_SEL_REG;
        case (func3)
          `FUNC3_BEQ:   exu_opt = `EXU_BEQ;
          `FUNC3_BNE:   exu_opt = `EXU_BNE;
          `FUNC3_BLT:   exu_opt = `EXU_BLT;
          `FUNC3_BGE:   exu_opt = `EXU_BGE;
          `FUNC3_BLTU:  exu_opt = `EXU_BLTU;
          `FUNC3_BGEU:  exu_opt = `EXU_BGEU; 
          default:  ;
        endcase
      end
      `TYPE_I:begin
        exu_src_sel = `EXU_SEL_IMM;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   exu_opt = `EXU_ADD; 
          `FUNC3_SRL_SRA_DIVU:  if(ins[30]) exu_opt = `EXU_SRA; else exu_opt = `EXU_SRL;
          `FUNC3_SLL_MULH:      exu_opt = `EXU_SLL;
          `FUNC3_XOR_DIV:       exu_opt = `EXU_XOR;
          `FUNC3_OR_REM:        exu_opt = `EXU_OR ;
          `FUNC3_AND_REMU:      exu_opt = `EXU_AND;
          `FUNC3_SLT_MULHSU:    exu_opt = `EXU_SLT;
          `FUNC3_SLTU_MULHU:    exu_opt = `EXU_SLTU;
          default:  ;
        endcase
      end
      `TYPE_I_W: begin
        exu_src_sel = `EXU_SEL_IMM;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   exu_opt = `EXU_ADDW;
          `FUNC3_SRL_SRA_DIVU:  if(ins[30]) exu_opt = `EXU_SRAW; else exu_opt = `EXU_SRLW;
          `FUNC3_SLL_MULH:      exu_opt = `EXU_SLLW;
          default:  ;
        endcase
      end
      `TYPE_R: begin
        exu_src_sel = `EXU_SEL_REG;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   if(ins[25]) exu_opt = `EXU_MUL;     else if(ins[30]) exu_opt = `EXU_SUB;  else exu_opt = `EXU_ADD;
          `FUNC3_SRL_SRA_DIVU:  if(ins[25]) exu_opt = `EXU_DIVU;    else if(ins[30]) exu_opt = `EXU_SRA;  else exu_opt = `EXU_SRL;
          `FUNC3_SLL_MULH:      if(ins[25]) exu_opt = `EXU_MULH;    else exu_opt = `EXU_SLL;
          `FUNC3_XOR_DIV:       if(ins[25]) exu_opt = `EXU_DIV;     else exu_opt = `EXU_XOR;
          `FUNC3_OR_REM:        if(ins[25]) exu_opt = `EXU_REM;     else exu_opt = `EXU_OR ;
          `FUNC3_AND_REMU:      if(ins[25]) exu_opt = `EXU_REMU;    else exu_opt = `EXU_AND;
          `FUNC3_SLT_MULHSU:    if(ins[25]) exu_opt = `EXU_MULHSU;  else exu_opt = `EXU_SLT;
          `FUNC3_SLTU_MULHU:    if(ins[25]) exu_opt = `EXU_MULHU;   else exu_opt = `EXU_SLTU;
          default:  ;
        endcase
      end
      `TYPE_R_W: begin
        exu_src_sel = `EXU_SEL_REG;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   if(ins[25]) exu_opt = `EXU_MULW;   else if(ins[30]) exu_opt = `EXU_SUBW; else exu_opt = `EXU_ADDW;
          `FUNC3_SRL_SRA_DIVU:  if(ins[25]) exu_opt = `EXU_DIVUW;  else if(ins[30]) exu_opt = `EXU_SRAW; else exu_opt = `EXU_SRLW;
          `FUNC3_XOR_DIV:       exu_opt = `EXU_DIVW;
          `FUNC3_OR_REM:        exu_opt = `EXU_REMW;
          `FUNC3_AND_REMU:      exu_opt = `EXU_REMUW;
          `FUNC3_SLL_MULH:      exu_opt = `EXU_SLLW;
          default:  ;
        endcase
      end
      default:  ;
    endcase
  end

  // 4.lsu:  ///////////////////////////////////////////////////////////////////////
  always@(*)begin
    case (opcode)
      `TYPE_I_LOAD: lsu_opt = {func3,1'b0};
      `TYPE_S:      lsu_opt = {func3,1'b1};
      default:      lsu_opt = `LSU_NOP;
    endcase
  end

  // 5.pcu: branch,jal,jalr:  ////////////////////////////////////////////////////////////////////
  assign brch = (opcode == `TYPE_B)? 1:0;
  assign jal = (opcode == `TYPE_J)? 1:0;
  assign jalr = (opcode == `TYPE_I_JALR)? 1:0;

endmodule
