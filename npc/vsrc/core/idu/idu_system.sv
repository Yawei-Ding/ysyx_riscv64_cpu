`include "defines.sv"
module idu_system(
  input        [`INS_WIDTH-1:0]     i_ins         ,
  // 1. for csr:
  output logic [`CSR_ADDRW-1:0]     o_csrsid      ,
  output logic                      o_csrsren     , // csr source read enable.
  // 2. for reg:
  output logic [`REG_ADDRW-1:0]     o_rs1id       ,
  // 3. for exu:
  output logic [`CPU_WIDTH-1:0]     o_imm         ,
  output logic [`CSR_OPT_WIDTH-1:0] o_excsropt    , //exu csr option.
  output logic                      o_excsrsrc    , //exu csr source.
  // 4. for wbu:
  output logic [`REG_ADDRW-1:0]     o_rdid        ,
  output logic                      o_rdwen       ,
  output logic [`CSR_ADDRW-1:0]     o_csrdid      ,
  output logic                      o_csrdwen       // csr dest write enable.
);

  // when reach here, opcode must be `TYPE_SYS, so it is senseless to case opcode.

  wire [2:0] func3;
  wire [4:0] uimm ;

  assign o_csrsid = i_ins[31:20];
  assign o_csrdid = i_ins[31:20];
  assign o_rs1id  = i_ins[19:15];
  assign uimm     = i_ins[19:15];
  assign func3    = i_ins[14:12];
  assign o_rdid   = i_ins[11: 7];

  wire csrrw  = (func3 == `FUNC3_CSRRW );
  wire csrrs  = (func3 == `FUNC3_CSRRS );
  wire csrrc  = (func3 == `FUNC3_CSRRC );
  wire csrrwi = (func3 == `FUNC3_CSRRWI);
  wire csrrsi = (func3 == `FUNC3_CSRRSI);
  wire csrrci = (func3 == `FUNC3_CSRRCI);
  wire rdneq0 = |o_rdid ;     // rd id not qual to zero.
  wire rsneq0 = |o_rs1id;     // rs id not qual to zero.

  assign o_csrsren =  ((csrrw | csrrwi) & rdneq0) | (csrrs | csrrsi | csrrc | csrrci);

  assign o_csrdwen =  (csrrw | csrrwi) | (rsneq0 & (csrrs | csrrsi | csrrc | csrrci));

  assign o_rdwen = o_csrsren & (o_rdid!=0);

  assign o_excsropt = func3[1:0];   // please read the riscv-pri and riscv-spec manual, 00 for mret,ecall,ebreak... 01,10,11 for rw/rs/rc.

  assign o_excsrsrc = (csrrwi|csrrsi|csrrci) ? `CSR_SEL_IMM : `CSR_SEL_REG;

  assign o_imm = (o_excsrsrc == `CSR_SEL_IMM) ? {{(`CPU_WIDTH-5){ 1'b0 }} , uimm} : `CPU_WIDTH'b0;

endmodule
