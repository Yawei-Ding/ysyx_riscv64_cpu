
// cpu width define:
`define CPU_WIDTH 64
`define INS_WIDTH 32
`define REG_COUNT (1<<`REG_ADDRW)
`define REG_ADDRW 5

// opcode -> ins type:
`define TYPE_R          7'b0110011  //R type for add/sub/sll/srl/sra/mul/mulh/mulhsu/mulhu/div/divu/rem/remu
`define TYPE_R_W        7'b0111011  //R type for addw/subw/sllw/srlw/sraw/mulw/divw/divuw/remw/remuw 
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
`define FUNC3_ADD_SUB_MUL       3'b000        //ADDI ADDIW ADD ADDW SUB SUBW MUL MULW
`define FUNC3_SLL_MULH          3'b001        //SLL SLLI SLLW SLLIW MULH
`define FUNC3_SLT_MULHSU        3'b010        //SLT SLTI MULHSU
`define FUNC3_SLTU_MULHU        3'b011        //STLU STLUI MULHU
`define FUNC3_XOR_DIV           3'b100        //XOR XORI DIV DIVW
`define FUNC3_SRL_SRA_DIVU      3'b101        //SRL SRLI SRA SRAI SRLW SRLIW SRAW SRAIW DIVU DIVUW
`define FUNC3_OR_REM            3'b110        //OR ORI REM REMW
`define FUNC3_AND_REMU          3'b111        //AND ANDI REMU REMUW

`define FUNC3_BEQ               3'b000
`define FUNC3_BNE               3'b001
`define FUNC3_BLT               3'b100
`define FUNC3_BGE               3'b101
`define FUNC3_BLTU              3'b110
`define FUNC3_BGEU              3'b111

`define FUNC3_LB_SB             3'b000
`define FUNC3_LH_SH             3'b001
`define FUNC3_LW_SW             3'b010
`define FUNC3_LD_SD             3'b011
`define FUNC3_LBU               3'b100
`define FUNC3_LHU               3'b101
`define FUNC3_LWU               3'b110

// EXU source selection:
`define EXU_SEL_WIDTH   2
`define EXU_SEL_REG     `EXU_SEL_WIDTH'b00
`define EXU_SEL_IMM     `EXU_SEL_WIDTH'b01
`define EXU_SEL_PC4     `EXU_SEL_WIDTH'b10
`define EXU_SEL_PCI     `EXU_SEL_WIDTH'b11

// EXU opreator:
`define EXU_OPT_WIDTH   6
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
`define EXU_MUL         `EXU_OPT_WIDTH'h14
`define EXU_MULH        `EXU_OPT_WIDTH'h15
`define EXU_MULHSU      `EXU_OPT_WIDTH'h16
`define EXU_MULHU       `EXU_OPT_WIDTH'h17
`define EXU_DIV         `EXU_OPT_WIDTH'h18
`define EXU_DIVU        `EXU_OPT_WIDTH'h19
`define EXU_REM         `EXU_OPT_WIDTH'h20
`define EXU_REMU        `EXU_OPT_WIDTH'h21
`define EXU_MULW        `EXU_OPT_WIDTH'h22
`define EXU_DIVW        `EXU_OPT_WIDTH'h23
`define EXU_DIVUW       `EXU_OPT_WIDTH'h24
`define EXU_REMW        `EXU_OPT_WIDTH'h25
`define EXU_REMUW       `EXU_OPT_WIDTH'h26
`define EXU_SLT         `EXU_OPT_WIDTH'h27
`define EXU_SLTU        `EXU_OPT_WIDTH'h28
