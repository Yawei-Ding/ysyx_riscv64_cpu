module iru (
  // wbu:
  input   logic                   i_wbu_valid   ,
  input   logic                   i_wbu_ready   ,
  input   logic [`CPU_WIDTH-1:0]  i_wbu_pc      ,
  input   logic                   i_wbu_ecall   ,
  input   logic                   i_wbu_mret    ,
  input   logic                   i_wbu_nop     ,

  // for bru:
  output  logic                   o_iru_excp   ,
  output  logic                   o_iru_intr   ,
  output  logic [`CPU_WIDTH-1:0]  o_iru_pc     ,

  // csr_file:
  input   logic [`CPU_WIDTH-1:0]  i_mie          ,
  input   logic [`CPU_WIDTH-1:0]  i_mip          ,
  input   logic [`CPU_WIDTH-1:0]  i_mtvec        ,  // ecall.
  input   logic [`CPU_WIDTH-1:0]  i_mepc         ,  // mret.
  input   logic [`CPU_WIDTH-1:0]  i_mstatus      ,  // ecall.
  output  logic                   o_mepc_wen     ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mepc_wdata   ,  // ecall.
  output  logic                   o_mcause_wen   ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mcause_wdata ,  // ecall.
  output  logic                   o_mstatus_wen  ,  // ecall.
  output  logic [`CPU_WIDTH-1:0]  o_mstatus_wdata   // ecall.
);

  // i_wbu_valid & (!i_wbu_nop) is used for waitting next correct pc!
  wire timer = i_wbu_valid & (!i_wbu_nop) & i_mip[`M_MIP_MTIP] & i_mstatus[`M_STATUS_MIE] & i_mie[`M_MIE_MTIE]; // timer irq pending.

  assign o_iru_excp = i_wbu_ecall | i_wbu_mret;  // trap.
  assign o_iru_intr = timer;                     // interrupt.

  assign o_iru_pc = (i_wbu_ecall | timer) ? i_mtvec : (i_wbu_mret ? i_mepc : `CPU_WIDTH'b0);

  assign o_mepc_wen = i_wbu_ready & (timer | i_wbu_ecall);
  assign o_mepc_wdata = i_wbu_pc;

  assign o_mcause_wen = i_wbu_ready & (timer | i_wbu_ecall);
  assign o_mcause_wdata = timer ? `IRQ_TIMER : (i_wbu_ecall ? `IRQ_ECALL : `CPU_WIDTH'b0);

  assign o_mstatus_wen = i_wbu_ready & (o_iru_excp | o_iru_intr);

  logic [`CPU_WIDTH-1:0] ecall_intr_mstatus_wdata;
  assign ecall_intr_mstatus_wdata[63:13]          = i_mstatus[63:13];
  assign ecall_intr_mstatus_wdata[`M_STATUS_MPP]  = `M_MODE;
  assign ecall_intr_mstatus_wdata[10:8]           = i_mstatus[10:8];
  assign ecall_intr_mstatus_wdata[`M_STATUS_MPIE] = i_mstatus[`M_STATUS_MIE];
  assign ecall_intr_mstatus_wdata[6:4]            = i_mstatus[6:4];
  assign ecall_intr_mstatus_wdata[`M_STATUS_MIE]  = 1'b0;
  assign ecall_intr_mstatus_wdata[2:0]            = i_mstatus[2:0];

  logic [`CPU_WIDTH-1:0] mret_mstatus_wdata;
  assign mret_mstatus_wdata[63:13]          = i_mstatus[63:13];
  assign mret_mstatus_wdata[`M_STATUS_MPP]  = 2'b0;
  assign mret_mstatus_wdata[10:8]           = i_mstatus[10:8];
  assign mret_mstatus_wdata[`M_STATUS_MPIE] = 1'b1;
  assign mret_mstatus_wdata[6:4]            = i_mstatus[6:4];
  assign mret_mstatus_wdata[`M_STATUS_MIE]  = i_mstatus[`M_STATUS_MPIE];
  assign mret_mstatus_wdata[2:0]            = i_mstatus[2:0];

  assign o_mstatus_wdata =  o_iru_intr | i_wbu_ecall  ? ecall_intr_mstatus_wdata :
                            (  i_wbu_mret    ? mret_mstatus_wdata  : `CPU_WIDTH'b0);

endmodule
