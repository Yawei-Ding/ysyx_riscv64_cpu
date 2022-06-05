`include "vsrc/lib/define.sv"
module idu(
  input        [31:0]               i_ins,
  output logic [`REG_ADDRW-1:0]     o_rdid ,      //for reg.
  output logic [`REG_ADDRW-1:0]     o_rs1id,      //for reg.
  output logic [`REG_ADDRW-1:0]     o_rs2id,      //for reg.
  output logic                      o_rdwen,      //for reg.
  output logic [`CPU_WIDTH-1:0]     o_imm  ,      //for exu.
  output logic [`EXU_SEL_WIDTH-1:0] o_exu_src_sel,//for exu.
  output logic [`EXU_OPT_WIDTH-1:0] o_exu_opt,    //for exu.
  output logic [`LSU_OPT_WIDTH-1:0] o_lsu_opt,    //for lsu.
  output logic                      o_brch,       //for pcu.
  output logic                      o_jal ,       //for pcu.
  output logic                      o_jalr        //for pcu.
);

  // ebreak & ecall are not supperted now. ebreak will cause system finish.
  //wire [6:0] func7  = i_ins[31:25]; // no use, warning.
  wire [4:0] rs2id  = i_ins[24:20];
  wire [4:0] rs1id  = i_ins[19:15];
  wire [2:0] func3  = i_ins[14:12];
  wire [4:0] rd     = i_ins[11: 7];
  wire [6:0] opcode = i_ins[ 6: 0];

  //1.reg info:  ////////////////////////////////////////////////////////////////////
  always@(*)begin
    o_rs2id = `REG_ADDRW'b0;
    o_rs1id = `REG_ADDRW'b0;
    o_rdid  = `REG_ADDRW'b0;
    o_rdwen = 1'b0;
    case(opcode) 
      `TYPE_R:        begin o_rs2id = rs2id;  o_rs1id = rs1id;  o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_R_W:      begin o_rs2id = rs2id;  o_rs1id = rs1id;  o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_S:        begin o_rs2id = rs2id;  o_rs1id = rs1id;                                end
      `TYPE_B:        begin o_rs2id = rs2id;  o_rs1id = rs1id;                                end
      `TYPE_I:        begin                   o_rs1id = rs1id;  o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_I_W:      begin                   o_rs1id = rs1id;  o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_I_LOAD:   begin                   o_rs1id = rs1id;  o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_I_JALR:   begin                   o_rs1id = rs1id;  o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_I_EBRK:   begin                   o_rs1id = rs1id;  o_rdid = rd;                  end
      `TYPE_U_LUI:    begin                   o_rs1id = 0  ;    o_rdid = rd;  o_rdwen = 1'b1; end //LUI: rd = x0 + imm;
      `TYPE_U_AUIPC:  begin                                     o_rdid = rd;  o_rdwen = 1'b1; end
      `TYPE_J:        begin                                     o_rdid = rd;  o_rdwen = 1'b1; end
      default:  ;
    endcase
  end

  //2.o_imm info:  ////////////////////////////////////////////////////////////////////
  always@(*)begin
    case (opcode)
      `TYPE_R:        o_imm = `CPU_WIDTH'b0;
      `TYPE_R_W:      o_imm = `CPU_WIDTH'b0;
      `TYPE_S:        o_imm = {{52{i_ins[31]}},i_ins[31:25],i_ins[11:7]};
      `TYPE_B:        o_imm = {{52{i_ins[31]}},i_ins[7],i_ins[30:25],i_ins[11:8],1'b0};
      `TYPE_I_W:      o_imm = {{52{i_ins[31]}},i_ins[31:20]};
      `TYPE_I_LOAD:   o_imm = {{52{i_ins[31]}},i_ins[31:20]};
      `TYPE_I_JALR:   o_imm = {{52{i_ins[31]}},i_ins[31:20]};
      `TYPE_I_EBRK:   o_imm = {{52{i_ins[31]}},i_ins[31:20]};
      `TYPE_U_LUI:    o_imm = {{32{i_ins[31]}},i_ins[31:12],12'b0};
      `TYPE_U_AUIPC:  o_imm = {{32{i_ins[31]}},i_ins[31:12],12'b0};
      `TYPE_J:        o_imm = {{44{i_ins[31]}},i_ins[19:12],i_ins[20],i_ins[30:21],1'b0};
      `TYPE_I:        o_imm = {{52{i_ins[31]}},i_ins[31:20]};
      default:        o_imm = `CPU_WIDTH'b0;
    endcase
  end

  //3.alu info:  ////////////////////////////////////////////////////////////////////
  always @(*) begin
    o_exu_opt     = `EXU_ADD;
    o_exu_src_sel = `EXU_SEL_IMM;
    case (opcode)
      `TYPE_S:        begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_IMM; end // M[rs1+imm] = rs2
      `TYPE_I_EBRK:   begin                                                      end // no use, dirct break.
      `TYPE_I_LOAD:   begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_IMM; end // rd = M[rs1+imm]
      `TYPE_I_JALR:   begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_PC4; end // rd = PC+4
      `TYPE_J:        begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_PC4; end // rd = PC+4
      `TYPE_U_LUI:    begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_IMM; end // rd = x0 + imm
      `TYPE_U_AUIPC:  begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_PCI; end // rd = pc + imm
      `TYPE_B: begin
        o_exu_src_sel = `EXU_SEL_REG;
        case (func3)
          `FUNC3_BEQ:   o_exu_opt = `EXU_BEQ;
          `FUNC3_BNE:   o_exu_opt = `EXU_BNE;
          `FUNC3_BLT:   o_exu_opt = `EXU_BLT;
          `FUNC3_BGE:   o_exu_opt = `EXU_BGE;
          `FUNC3_BLTU:  o_exu_opt = `EXU_BLTU;
          `FUNC3_BGEU:  o_exu_opt = `EXU_BGEU; 
          default:  ;
        endcase
      end
      `TYPE_I:begin
        o_exu_src_sel = `EXU_SEL_IMM;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   o_exu_opt = `EXU_ADD; 
          `FUNC3_SRL_SRA_DIVU:  if(i_ins[30]) o_exu_opt = `EXU_SRA; else o_exu_opt = `EXU_SRL;
          `FUNC3_SLL_MULH:      o_exu_opt = `EXU_SLL;
          `FUNC3_XOR_DIV:       o_exu_opt = `EXU_XOR;
          `FUNC3_OR_REM:        o_exu_opt = `EXU_OR ;
          `FUNC3_AND_REMU:      o_exu_opt = `EXU_AND;
          `FUNC3_SLT_MULHSU:    o_exu_opt = `EXU_SLT;
          `FUNC3_SLTU_MULHU:    o_exu_opt = `EXU_SLTU;
          default:  ;
        endcase
      end
      `TYPE_I_W: begin
        o_exu_src_sel = `EXU_SEL_IMM;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   o_exu_opt = `EXU_ADDW;
          `FUNC3_SRL_SRA_DIVU:  if(i_ins[30]) o_exu_opt = `EXU_SRAW; else o_exu_opt = `EXU_SRLW;
          `FUNC3_SLL_MULH:      o_exu_opt = `EXU_SLLW;
          default:  ;
        endcase
      end
      `TYPE_R: begin
        o_exu_src_sel = `EXU_SEL_REG;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   if(i_ins[25]) o_exu_opt = `EXU_MUL;     else if(i_ins[30]) o_exu_opt = `EXU_SUB;  else o_exu_opt = `EXU_ADD;
          `FUNC3_SRL_SRA_DIVU:  if(i_ins[25]) o_exu_opt = `EXU_DIVU;    else if(i_ins[30]) o_exu_opt = `EXU_SRA;  else o_exu_opt = `EXU_SRL;
          `FUNC3_SLL_MULH:      if(i_ins[25]) o_exu_opt = `EXU_MULH;    else o_exu_opt = `EXU_SLL;
          `FUNC3_XOR_DIV:       if(i_ins[25]) o_exu_opt = `EXU_DIV;     else o_exu_opt = `EXU_XOR;
          `FUNC3_OR_REM:        if(i_ins[25]) o_exu_opt = `EXU_REM;     else o_exu_opt = `EXU_OR ;
          `FUNC3_AND_REMU:      if(i_ins[25]) o_exu_opt = `EXU_REMU;    else o_exu_opt = `EXU_AND;
          `FUNC3_SLT_MULHSU:    if(i_ins[25]) o_exu_opt = `EXU_MULHSU;  else o_exu_opt = `EXU_SLT;
          `FUNC3_SLTU_MULHU:    if(i_ins[25]) o_exu_opt = `EXU_MULHU;   else o_exu_opt = `EXU_SLTU;
          default:  ;
        endcase
      end
      `TYPE_R_W: begin
        o_exu_src_sel = `EXU_SEL_REG;
        case (func3)
          `FUNC3_ADD_SUB_MUL:   if(i_ins[25]) o_exu_opt = `EXU_MULW;   else if(i_ins[30]) o_exu_opt = `EXU_SUBW; else o_exu_opt = `EXU_ADDW;
          `FUNC3_SRL_SRA_DIVU:  if(i_ins[25]) o_exu_opt = `EXU_DIVUW;  else if(i_ins[30]) o_exu_opt = `EXU_SRAW; else o_exu_opt = `EXU_SRLW;
          `FUNC3_XOR_DIV:       o_exu_opt = `EXU_DIVW;
          `FUNC3_OR_REM:        o_exu_opt = `EXU_REMW;
          `FUNC3_AND_REMU:      o_exu_opt = `EXU_REMUW;
          `FUNC3_SLL_MULH:      o_exu_opt = `EXU_SLLW;
          default:  ;
        endcase
      end
      default:  ;
    endcase
  end

  // 4.lsu:  ///////////////////////////////////////////////////////////////////////
  always@(*)begin
    case (opcode)
      `TYPE_I_LOAD: o_lsu_opt = {func3,1'b0};
      `TYPE_S:      o_lsu_opt = {func3,1'b1};
      default:      o_lsu_opt = `LSU_NOP;
    endcase
  end

  // 5.pcu: branch,o_jal,o_jalr:  ////////////////////////////////////////////////////////////////////
  assign o_brch = (opcode == `TYPE_B)? 1:0;
  assign o_jal  = (opcode == `TYPE_J)? 1:0;
  assign o_jalr = (opcode == `TYPE_I_JALR)? 1:0;

endmodule
