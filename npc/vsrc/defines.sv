
// 1. for soc sys://////////////////////////////////////////////////////////////////////////////////////////
`define RISCV_PRIV_MODE_U   0
`define RISCV_PRIV_MODE_S   1
`define RISCV_PRIV_MODE_M   3

// 2. for cache:////////////////////////////////////////////////////////////////////////////////////////////

`define TAG_W          `ADR_WIDTH-11
`define VLD_W           1
`define DRT_W           1
`define dTARY_W         `TAG_W+`VLD_W+`DRT_W // tag + valid + dirty.
`define iTARY_W         `TAG_W+`VLD_W

`define TAG_BIT        `TAG_W-1:0
`define VLD_BIT        `TAG_W
`define DRT_BIT        `TAG_W+`VLD_W

// 3. for cpu core://///////////////////////////////////////////////////////////////////////////////////////

// cpu width define:
`define CPU_WIDTH 64
`define ADR_WIDTH 32
`define INS_WIDTH 32
`define REG_COUNT (1<<`REG_ADDRW)
`define REG_ADDRW 5

// opcode -> ins type:
`define TYPE_R          7'b0110011  //  R type for add/sub/sll/srl/sra/mul/mulh/mulhsu/mulhu/div/divu/rem/remu
`define TYPE_R_W        7'b0111011  //  R type for addw/subw/sllw/srlw/sraw/mulw/divw/divuw/remw/remuw 
`define TYPE_S          7'b0100011  //  S type
`define TYPE_B          7'b1100011  //  B type
`define TYPE_I          7'b0010011  //  I type for addi/slli/srli/srai/xori/ori/andi
`define TYPE_I_W        7'b0011011  //  I type for addiw/slliw/srliw/sraiw
`define TYPE_I_LOAD     7'b0000011  //  I type for lb/lh/lw/lbu/lhu
`define TYPE_I_JALR     7'b1100111  //  I type for jalr
`define TYPE_U_LUI      7'b0110111  //  U type for lui
`define TYPE_U_AUIPC    7'b0010111  //  U type for auipc
`define TYPE_J          7'b1101111  //  J type for jal
`define TYPE_SYS        7'b1110011  //  SYS type for ecall/ebreak/csrrw/csrrs/csrrc
`define TYPE_FENCE      7'b0001111  //  FENCE type for fence.i

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
`define EXU_NOP         `EXU_OPT_WIDTH'h0
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


// 4. for cpu csr ://////////////////////////////////////////////////////////////////////////////////////////

// csr regfile define:
`define M_MODE          2'b11
`define CSR_COUNT       (1<<`CSR_ADDRW)
`define CSR_ADDRW       12
`define ADDR_MSTATUS    `CSR_ADDRW'h300
`define ADDR_MTVEC      `CSR_ADDRW'h305
`define ADDR_MEPC       `CSR_ADDRW'h341
`define ADDR_MCAUSE     `CSR_ADDRW'h342
`define ADDR_MCYCLE     `CSR_ADDRW'hb00
`define ADDR_MIP        `CSR_ADDRW'h344
`define ADDR_MIE        `CSR_ADDRW'h304
`define ADDR_MSCRATCH   `CSR_ADDRW'h340

// csr_file bit define:
`define M_STATUS_MIE    3      // machine level interrupt enable.
`define M_STATUS_MPIE   7      // machine level previous interrupt enable.
`define M_STATUS_MPP    12:11  // machine level previous privilege mode
`define M_STATUS_VS     10:9   // machine level previous privilege mode
`define M_STATUS_FS     14:13  // machine level previous privilege mode
`define M_STATUS_XS     16:15  // machine level previous privilege mode
`define M_STATUS_SD     63

`define M_MIE_MTIE      7      // machine interrupt enable, machine timer interrupt enable.
`define M_MIP_MTIP      7      // machine interrupt pending, machine timer interrupt pending.

// csr fun3:
`define FUNC3_ECL_EBRK  3'b000  //for ecall, ebreak.
`define FUNC3_CSRRW     3'b001
`define FUNC3_CSRRS     3'b010
`define FUNC3_CSRRC     3'b011
`define FUNC3_CSRRWI    3'b101
`define FUNC3_CSRRSI    3'b110
`define FUNC3_CSRRCI    3'b111

// csr opreator for exu:
`define CSR_OPT_WIDTH   2
`define CSR_NOP         `CSR_OPT_WIDTH'b00
`define CSR_RW          `CSR_OPT_WIDTH'b01
`define CSR_RS          `CSR_OPT_WIDTH'b10
`define CSR_RC          `CSR_OPT_WIDTH'b11

`define CSR_SEL_REG     1'b0
`define CSR_SEL_IMM     1'b1

// clint define:
`define CLINT_BASE_ADDR `ADR_WIDTH'h02000000
`define CLINT_END_ADDR  `ADR_WIDTH'h0200ffff
`define UART_BASE_ADDR  `ADR_WIDTH'h10000000
`define UART_END_ADDR   `ADR_WIDTH'h10000fff
`define MSIP_ADDR       `CLINT_BASE_ADDR+`ADR_WIDTH'h0000
`define MTIMECMP_ADDR   `CLINT_BASE_ADDR+`ADR_WIDTH'h4000
`define MTIME_ADDR      `CLINT_BASE_ADDR+`ADR_WIDTH'hBFF8

// intr define:
`define IRQ_TIMER       `CPU_WIDTH'h80000000_00000007
`define IRQ_ECALL       `CPU_WIDTH'd11


// 5. for axi bus://////////////////////////////////////////////////////////////////////////////////////////

`define SIZE_B              2'b00
`define SIZE_H              2'b01
`define SIZE_W              2'b10
`define SIZE_D              2'b11

`define REQ_READ            1'b0
`define REQ_WRITE           1'b1

// AXI interface signals define://////////////////////////////////////////////////////////////
// Burst types
`define AXI_BURST_TYPE_FIXED                                2'b00
`define AXI_BURST_TYPE_INCR                                 2'b01
`define AXI_BURST_TYPE_WRAP                                 2'b10
// Access permissions
`define AXI_PROT_UNPRIVILEGED_ACCESS                        3'b000
`define AXI_PROT_PRIVILEGED_ACCESS                          3'b001
`define AXI_PROT_SECURE_ACCESS                              3'b000
`define AXI_PROT_NON_SECURE_ACCESS                          3'b010
`define AXI_PROT_DATA_ACCESS                                3'b000
`define AXI_PROT_INSTRUCTION_ACCESS                         3'b100
// Memory types (AR)
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
// Memory types (AW)
`define AXI_AWCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_AWCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_AWCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1110
`define AXI_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_AWCACHE_WRITE_BACK_NO_ALLOCATE                  4'b0111
`define AXI_AWCACHE_WRITE_BACK_READ_ALLOCATE                4'b0111
`define AXI_AWCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1111
`define AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
