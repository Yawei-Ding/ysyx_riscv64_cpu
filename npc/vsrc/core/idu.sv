`include "config.sv"
module idu(
  input        [31:0]               i_ins         ,
  input                             i_rst_n       , //for sim.
  output logic [`REG_ADDRW-1:0]     o_rdid        , //for reg.
  output logic [`REG_ADDRW-1:0]     o_rs1id       , //for reg.
  output logic [`REG_ADDRW-1:0]     o_rs2id       , //for reg.
  output logic                      o_rdwen       , //for reg.
  output logic [`CPU_WIDTH-1:0]     o_imm         , //for exu.
  output logic [`EXU_SEL_WIDTH-1:0] o_exu_src_sel , //for exu.
  output logic [`EXU_OPT_WIDTH-1:0] o_exu_opt     , //for exu.
  output logic [`LSU_OPT_WIDTH-1:0] o_lsu_opt     , //for lsu.
  output logic                      o_brch        , //for pcu.
  output logic                      o_jal         , //for pcu.
  output logic                      o_jalr          //for pcu.
);

  // ebreak & ecall are not supperted now. ebreak will cause system finish.
  wire [6:0] func7  = i_ins[31:25];
  wire [4:0] rs2id  = i_ins[24:20];
  wire [4:0] rs1id  = i_ins[19:15];
  wire [2:0] func3  = i_ins[14:12];
  wire [4:0] rdid   = i_ins[11: 7];
  wire [6:0] opcode = i_ins[ 6: 0];

  //1.reg info, imm info:  ///////////////////////////////////////////////////////////////////////////
  always@(*)begin
    o_imm   = `CPU_WIDTH'b0;
    o_rs1id = `REG_ADDRW'b0;
    o_rs2id = `REG_ADDRW'b0;
    o_rdid  = `REG_ADDRW'b0;
    o_rdwen = 1'b0;
    case(opcode) 
      `TYPE_R:        begin o_rs2id = rs2id;  o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = `CPU_WIDTH'b0;                                              end
      `TYPE_R_W:      begin o_rs2id = rs2id;  o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = `CPU_WIDTH'b0;                                              end
      `TYPE_S:        begin o_rs2id = rs2id;  o_rs1id = rs1id;                                  o_imm = {{52{i_ins[31]}},i_ins[31:25],i_ins[11:7]};                 end
      `TYPE_B:        begin o_rs2id = rs2id;  o_rs1id = rs1id;                                  o_imm = {{52{i_ins[31]}},i_ins[7],i_ins[30:25],i_ins[11:8],1'b0};   end
      `TYPE_I:        begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
      `TYPE_I_W:      begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
      `TYPE_I_LOAD:   begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
      `TYPE_I_JALR:   begin                   o_rs1id = rs1id;  o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
      `TYPE_I_EBRK:   begin                   o_rs1id = rs1id;  o_rdid = rdid;                  o_imm = {{52{i_ins[31]}},i_ins[31:20]};                             end
      `TYPE_U_LUI:    begin                   o_rs1id = 0  ;    o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{32{i_ins[31]}},i_ins[31:12],12'b0};                       end //LUI: rdid = x0 + imm;
      `TYPE_U_AUIPC:  begin                                     o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{32{i_ins[31]}},i_ins[31:12],12'b0};                       end
      `TYPE_J:        begin                                     o_rdid = rdid;  o_rdwen = 1'b1; o_imm = {{44{i_ins[31]}},i_ins[19:12],i_ins[20],i_ins[30:21],1'b0}; end
      default: ;
    endcase
  end

  //2.alu info:  /////////////////////////////////////////////////////////////////////////////////////
  logic [2:0] id_err; //bit0:opc_err, bit1:func3_err, bit2:func7_err
  always @(*) begin
    o_exu_opt     = `EXU_ADD;
    o_exu_src_sel = `EXU_SEL_IMM;
    id_err        = 3'b0;
    case (opcode)
      `TYPE_S:        begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_IMM; end // M[rs1+imm] = rs2
      `TYPE_I_EBRK:   begin                                                      end // no use, dirct break.
      `TYPE_I_LOAD:   begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_IMM; end // rdid = M[rs1+imm]
      `TYPE_I_JALR:   begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_PC4; end // rdid = PC+4
      `TYPE_J:        begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_PC4; end // rdid = PC+4
      `TYPE_U_LUI:    begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_IMM; end // rdid = x0 + imm
      `TYPE_U_AUIPC:  begin o_exu_opt = `EXU_ADD;  o_exu_src_sel = `EXU_SEL_PCI; end // rdid = pc + imm
      `TYPE_B:
        begin
          o_exu_src_sel = `EXU_SEL_REG;
          case (func3)
            `FUNC3_BEQ:   o_exu_opt = `EXU_BEQ;
            `FUNC3_BNE:   o_exu_opt = `EXU_BNE;
            `FUNC3_BLT:   o_exu_opt = `EXU_BLT;
            `FUNC3_BGE:   o_exu_opt = `EXU_BGE;
            `FUNC3_BLTU:  o_exu_opt = `EXU_BLTU;
            `FUNC3_BGEU:  o_exu_opt = `EXU_BGEU; 
            default:      id_err[1] = 1'b1; //func3_err
          endcase
        end
      `TYPE_I:
        begin
          o_exu_src_sel = `EXU_SEL_IMM;
          case (func3)
            `FUNC3_ADD_SUB_MUL:   o_exu_opt = `EXU_ADD; 
            `FUNC3_SLL_MULH:      o_exu_opt = `EXU_SLL;
            `FUNC3_SRL_SRA_DIVU:  case (func7[6:1]) 6'b000000: o_exu_opt = `EXU_SRL; 6'b010000:o_exu_opt = `EXU_SRA; default:id_err[2] = 1'b1; endcase
            `FUNC3_XOR_DIV:       o_exu_opt = `EXU_XOR;
            `FUNC3_OR_REM:        o_exu_opt = `EXU_OR ;
            `FUNC3_AND_REMU:      o_exu_opt = `EXU_AND;
            `FUNC3_SLT_MULHSU:    o_exu_opt = `EXU_SLT;
            `FUNC3_SLTU_MULHU:    o_exu_opt = `EXU_SLTU;
            default:              id_err[1] = 1'b1; //func3_err
          endcase
        end
      `TYPE_I_W:
        begin
          o_exu_src_sel = `EXU_SEL_IMM;
          case (func3)
            `FUNC3_ADD_SUB_MUL:   o_exu_opt = `EXU_ADDW;
            `FUNC3_SLL_MULH:      o_exu_opt = `EXU_SLLW;
            `FUNC3_SRL_SRA_DIVU:  case (func7) 7'b0000000:o_exu_opt = `EXU_SRLW; 7'b0100000: o_exu_opt = `EXU_SRAW;  default:id_err[2] = 1'b1; endcase
            default:              id_err[1] = 1'b1; //func3_err
          endcase
        end
      `TYPE_R:
        begin
          o_exu_src_sel = `EXU_SEL_REG;
          case (func3)
            `FUNC3_ADD_SUB_MUL:  case (func7) 7'b0000000:o_exu_opt = `EXU_ADD ; 7'b0000001: o_exu_opt = `EXU_MUL   ; 7'b0100000: o_exu_opt = `EXU_SUB; default:id_err[2] = 1'b1; endcase
            `FUNC3_SRL_SRA_DIVU: case (func7) 7'b0000000:o_exu_opt = `EXU_SRL ; 7'b0000001: o_exu_opt = `EXU_DIVU  ; 7'b0100000: o_exu_opt = `EXU_SRA; default:id_err[2] = 1'b1; endcase
            `FUNC3_SLL_MULH:     case (func7) 7'b0000000:o_exu_opt = `EXU_SLL ; 7'b0000001: o_exu_opt = `EXU_MULH  ; default:id_err[2] = 1'b1; endcase
            `FUNC3_XOR_DIV:      case (func7) 7'b0000000:o_exu_opt = `EXU_XOR ; 7'b0000001: o_exu_opt = `EXU_DIV   ; default:id_err[2] = 1'b1; endcase
            `FUNC3_OR_REM:       case (func7) 7'b0000000:o_exu_opt = `EXU_OR  ; 7'b0000001: o_exu_opt = `EXU_REM   ; default:id_err[2] = 1'b1; endcase
            `FUNC3_AND_REMU:     case (func7) 7'b0000000:o_exu_opt = `EXU_AND ; 7'b0000001: o_exu_opt = `EXU_REMU  ; default:id_err[2] = 1'b1; endcase
            `FUNC3_SLT_MULHSU:   case (func7) 7'b0000000:o_exu_opt = `EXU_SLT ; 7'b0000001: o_exu_opt = `EXU_MULHSU; default:id_err[2] = 1'b1; endcase
            `FUNC3_SLTU_MULHU:   case (func7) 7'b0000000:o_exu_opt = `EXU_SLTU; 7'b0000001: o_exu_opt = `EXU_MULHU ; default:id_err[2] = 1'b1; endcase
            default:              id_err[1] = 1'b1; //func3_err
          endcase
        end
      `TYPE_R_W:
        begin
          o_exu_src_sel = `EXU_SEL_REG;
          case (func3)
            `FUNC3_ADD_SUB_MUL:   case (func7) 7'b0000000:o_exu_opt = `EXU_ADDW; 7'b0100000: o_exu_opt = `EXU_SUBW; 7'b0000001: o_exu_opt = `EXU_MULW ; default:id_err[2] = 1'b1; endcase
            `FUNC3_SRL_SRA_DIVU:  case (func7) 7'b0000000:o_exu_opt = `EXU_SRLW; 7'b0100000: o_exu_opt = `EXU_SRAW; 7'b0000001: o_exu_opt = `EXU_DIVUW; default:id_err[2] = 1'b1; endcase
            `FUNC3_XOR_DIV:       o_exu_opt  = `EXU_DIVW;
            `FUNC3_OR_REM:        o_exu_opt  = `EXU_REMW;
            `FUNC3_AND_REMU:      o_exu_opt  = `EXU_REMUW;
            `FUNC3_SLL_MULH:      o_exu_opt  = `EXU_SLLW;
            default:              id_err[1] = 1'b1; //func3_err
          endcase
        end
      default:  id_err[0] = 1'b1; //opc_err
    endcase
  end

  // 3.lsu:  /////////////////////////////////////////////////////////////////////////////////////////
  always@(*)begin
    case (opcode)
      `TYPE_I_LOAD: o_lsu_opt = {func3,1'b0};
      `TYPE_S:      o_lsu_opt = {func3,1'b1};
      default:      o_lsu_opt = `LSU_NOP;
    endcase
  end

  // 4.pcu: branch,o_jal,o_jalr.  ////////////////////////////////////////////////////////////////////
  assign o_brch = (opcode == `TYPE_B)? 1:0;
  assign o_jal  = (opcode == `TYPE_J)? 1:0;
  assign o_jalr = (opcode == `TYPE_I_JALR)? 1:0;

  // 5.sim:  /////////////////////////////////////////////////////////////////////////////////////////
  always@(*)begin
    if(i_rst_n & |i_ins & id_err[0]) $display("\n----------ins decode error, ins = %x, opcode == %b---------------\n",i_ins,opcode);
    if(i_rst_n & |i_ins & id_err[1]) $display("\n----------ins decode error, ins = %x, funct3 == %b---------------\n",i_ins,func3 );
    if(i_rst_n & |i_ins & id_err[2]) $display("\n----------ins decode error, ins = %x, funct7 == %b---------------\n",i_ins,func7 );
    if(i_rst_n & |i_ins & |id_err ) $finish; //ins docode err.
  end

endmodule
