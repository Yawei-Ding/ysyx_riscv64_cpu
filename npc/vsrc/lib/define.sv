
// cpu width define:
`define CPU_WIDTH 64
`define REG_COUNT 1<<`REG_ADDRW
`define REG_ADDRW 5

// opcode -> ins type:
`define TYPE_R          7'b0110011  //R type for add sub sll srl sra
`define TYPE_R_W        7'b0111011  //R type for addw subw sllw srlw sraw
`define TYPE_S          7'b0100011  //S type
`define TYPE_B          7'b1100011  //B type
`define TYPE_I          7'b0010011  //I type for addi/slli/srli/srai/xori/ori/andi
`define TYPE_I_W        7'b0011011  //I type for addiw/slliw/srliw/sraiw
`define TYPE_I_LOAD     7'b0000011  //I type for lb/lh/lw/lbu/lhu
`define TYPE_I_JALR     7'b1100111  //I type for jalr
`define TYPE_I_EBRK     7'b1110011  //I type for ecall/ebreak
`define TYPE_U_LUI      7'b0110111  //U type for lui
`define TYPE_U_AUIPC    7'b0010111  //U type for auipc
`define TYPE_J          7'b1101111  //J type for jal

// function3:
`define FUNC3_ADD_SUB   3'h0        //ADDI ADDIW ADD ADDW SUB SUBW
`define FUNC3_XOR       3'h4        //XOR XORI
`define FUNC3_OR        3'h6        //OR ORI
`define FUNC3_AND       3'h7        //AND ANDI
`define FUNC3_SLL       3'h1        //SLL SLLI SLLW SLLIW
`define FUNC3_SRL_SRA   3'h5        //SRL SRLI SRA SRAI SRLW SRLIW SRAW SRAIW
`define FUNC3_SLT       3'h2        //SLT SLTI
`define FUNC3_SLTU      3'h3        //STLU STLUI
`define FUNC3_BEQ       3'h0
`define FUNC3_BNE       3'h1
`define FUNC3_BLT       3'h4
`define FUNC3_BGE       3'h5
`define FUNC3_BLTU      3'h6
`define FUNC3_BGEU      3'h7

`define FUNC3_LB        3'b000
`define FUNC3_LH        3'b001
`define FUNC3_LW        3'b010
`define FUNC3_LD        3'b011
`define FUNC3_LBU       3'b100
`define FUNC3_LHU       3'b101
`define FUNC3_LWU       3'b110
`define FUNC3_SB        3'b000
`define FUNC3_SH        3'b001
`define FUNC3_SW        3'b010
`define FUNC3_SD        3'b011


// EXU source selection:
`define EXU_SEL_WIDTH   2
`define EXU_SEL_REG     `EXU_SEL_WIDTH'b00
`define EXU_SEL_IMM     `EXU_SEL_WIDTH'b01
`define EXU_SEL_PC4     `EXU_SEL_WIDTH'b10
`define EXU_SEL_PCI     `EXU_SEL_WIDTH'b11

// EXU opreator:
`define EXU_OPT_WIDTH   8
`define EXU_ADD         `EXU_OPT_WIDTH'h1
`define EXU_SUB         `EXU_OPT_WIDTH'h2
`define EXU_ADDW        `EXU_OPT_WIDTH'h3
`define EXU_SUBW        `EXU_OPT_WIDTH'h4
`define EXU_AND         `EXU_OPT_WIDTH'h5
`define EXU_OR          `EXU_OPT_WIDTH'h6
`define EXU_XOR         `EXU_OPT_WIDTH'h7
`define EXU_SLL         `EXU_OPT_WIDTH'h8
`define EXU_SRL         `EXU_OPT_WIDTH'h9
`define EXU_SRA         `EXU_OPT_WIDTH'h10
`define EXU_SLLW        `EXU_OPT_WIDTH'h11
`define EXU_SRLW        `EXU_OPT_WIDTH'h12
`define EXU_SRAW        `EXU_OPT_WIDTH'h13
`define EXU_SLT         `EXU_OPT_WIDTH'h14
`define EXU_SLTU        `EXU_OPT_WIDTH'h15
`define EXU_BEQ         `EXU_OPT_WIDTH'h16
`define EXU_BNE         `EXU_OPT_WIDTH'h17
`define EXU_BLT         `EXU_OPT_WIDTH'h18
`define EXU_BGE         `EXU_OPT_WIDTH'h19
`define EXU_BLTU        `EXU_OPT_WIDTH'h20
`define EXU_BGEU        `EXU_OPT_WIDTH'h21

// ALU opreator:
`define ALU_ADD         `EXU_ADD
`define ALU_SUB         `EXU_SUB   //use for sub,slt,beq,bne,blt,bge 
`define ALU_ADDW        `EXU_ADDW
`define ALU_SUBW        `EXU_SUBW
`define ALU_AND         `EXU_AND
`define ALU_OR          `EXU_OR
`define ALU_XOR         `EXU_XOR
`define ALU_SLL         `EXU_SLL
`define ALU_SRL         `EXU_SRL
`define ALU_SRA         `EXU_SRA
`define ALU_SLLW        `EXU_SLLW
`define ALU_SRLW        `EXU_SRLW
`define ALU_SRAW        `EXU_SRAW
`define ALU_SUBU        `EXU_OPT_WIDTH'h22  //use for sltu,bltu,bgeu

`define LSU_OPT_WIDTH   4
`define LSU_LB          `LSU_OPT_WIDTH'b0000    //0 for load,  000 for FUNC3_LB
`define LSU_LH          `LSU_OPT_WIDTH'b0001    //0 for load,  001 for FUNC3_LH
`define LSU_LW          `LSU_OPT_WIDTH'b0010    //0 for load,  010 for FUNC3_LW
`define LSU_LD          `LSU_OPT_WIDTH'b0011    //0 for load,  011 for FUNC3_LD
`define LSU_LBU         `LSU_OPT_WIDTH'b0100    //0 for load,  100 for FUNC3_LBU
`define LSU_LHU         `LSU_OPT_WIDTH'b0101    //0 for load,  101 for FUNC3_LHU
`define LSU_LWU         `LSU_OPT_WIDTH'b0110    //0 for load,  110 for FUNC3_LWU
`define LSU_SB          `LSU_OPT_WIDTH'b1000    //1 for store, 000 for FUNC3_SB
`define LSU_SH          `LSU_OPT_WIDTH'b1001    //1 for store, 001 for FUNC3_SH
`define LSU_SW          `LSU_OPT_WIDTH'b1010    //1 for store, 010 for FUNC3_SW
`define LSU_SD          `LSU_OPT_WIDTH'b1011    //1 for store, 011 for FUNC3_SD
`define LSU_NOP         `LSU_OPT_WIDTH'b1111    //1111 for nop!! "highest bit = 0" <=> "this is an load ins"
