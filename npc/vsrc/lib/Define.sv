
// cpu width define:
`define CPU_WIDTH 64
`define REG_COUNT 32
`define REG_ADDRW $clog2(`REG_COUNT)


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


// ALU source selection:
`define ALU_SEL_WIDTH   2
`define ALU_SEL_REG     `ALU_SEL_WIDTH'b00
`define ALU_SEL_IMM     `ALU_SEL_WIDTH'b01
`define ALU_SEL_PC4     `ALU_SEL_WIDTH'b10
`define ALU_SEL_PCI     `ALU_SEL_WIDTH'b11

// ALU opreator:
`define ALU_OPT_WIDTH    8
`define ALU_ADD
`define ALU_SUB
`define ALU_ADDW
`define ALU_SUBW
`define ALU_AND
`define ALU_OR
`define ALU_XOR
`define ALU_SLL
`define ALU_SRL
`define ALU_SRA
`define ALU_SLLW
`define ALU_SRLW
`define ALU_SRAW
`define ALU_SLT
`define ALU_SLTU


