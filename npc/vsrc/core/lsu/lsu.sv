module lsu (
  input  logic                    i_clk         ,
  input  logic                    i_rst_n       ,
  input  logic                    i_flush       ,

  // 1. axi interface to get data from mem:
  uni_if.Master                   dCacheIf_M    ,

  // 2. signal to pipe shake hands:
  input  logic                    i_pre_valid   ,   // from pre-stage
  output logic                    o_pre_ready   ,   //  to  pre-stage
  output logic                    o_post_valid  ,   //  to  post-stage
  input  logic                    i_post_ready  ,   // from post-stage

  // 3. input comb signal from pre stage:
  input  logic  [`CPU_WIDTH-1:0]  i_exu_exres   ,
  input  logic  [`CPU_WIDTH-1:0]  i_exu_rs2     ,
  input  logic  [2:0]             i_exu_lsfunc3 ,
  input  logic                    i_exu_lden    ,
  input  logic                    i_exu_sten    ,
  input  logic                    i_exu_fencei  ,
  input  logic  [`REG_ADDRW-1:0]  i_exu_rdid    ,
  input  logic                    i_exu_rdwen   ,
  input  logic  [`CSR_ADDRW-1:0]  i_exu_csrdid  ,
  input  logic                    i_exu_csrdwen , // csr dest write enable.
  input  logic  [`CPU_WIDTH-1:0]  i_exu_csrd    ,
  input  logic  [`CPU_WIDTH-1:0]  i_exu_pc      ,
  input  logic                    i_exu_ecall   ,
  input  logic                    i_exu_mret    ,
  input  logic                    i_exu_nop     ,
  input  logic  [`INS_WIDTH-1:0]  s_exu_ins     ,

  // 4. iru signals:
  input  logic                    i_iru_excp    ,
  input  logic                    i_iru_intr    ,

  // 4. clint signals:
  output  logic                   o_clint_ren   ,
  output  logic [`ADR_WIDTH-1:0]  o_clint_raddr ,
  input   logic [`CPU_WIDTH-1:0]  i_clint_rdata ,
  output  logic                   o_clint_wen   ,
  output  logic [`ADR_WIDTH-1:0]  o_clint_waddr ,
  output  logic [`CPU_WIDTH-1:0]  o_clint_wdata ,

  // 5. output comb signal to post stage:
  output logic  [`CPU_WIDTH-1:0]  o_lsu_lsres   ,
  output logic  [`CPU_WIDTH-1:0]  o_lsu_exres   ,
  output logic                    o_lsu_lden    ,
  output logic                    o_lsu_fencei  ,
  output logic  [`REG_ADDRW-1:0]  o_lsu_rdid    ,
  output logic                    o_lsu_rdwen   ,
  output logic  [`CSR_ADDRW-1:0]  o_lsu_csrdid  ,
  output logic                    o_lsu_csrdwen , // csr dest write enable.
  output logic  [`CPU_WIDTH-1:0]  o_lsu_csrd    ,
  output logic  [`CPU_WIDTH-1:0]  o_lsu_pc      ,
  output logic                    o_lsu_ecall   ,
  output logic                    o_lsu_mret    ,
  output logic                    o_lsu_nop     ,

  // 6. for sim:
  output logic  [`INS_WIDTH-1:0]  s_lsu_ins     ,
  output logic                    s_lsu_lsclint ,
  output logic                    s_lsu_device
);

  // 1. shake hands to reg pre stage signals:////////////////////////////////s/////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  wire pre_valid_r;

  stl_reg #(
    .WIDTH      (1           ), 
    .RESET_VAL  (0           )
  ) postvalid (
  	.i_clk      (i_clk       ), 
    .i_rst_n    (i_rst_n     ), 
    .i_wen      (i_flush | o_pre_ready      ), 
    .i_din      (i_flush ? 1'b0: i_pre_valid), 
    .o_dout     (pre_valid_r )
  );

  wire ldst_en, en_axi, exu_fencei_r, pre_sh;
  assign o_post_valid = (exu_fencei_r | ldst_en & en_axi) ? dCacheIf_M.ready : pre_valid_r;
  assign o_pre_ready  = o_post_valid & i_post_ready | !pre_valid_r ;
  assign pre_sh       = i_pre_valid & o_pre_ready;

  logic  [`CPU_WIDTH-1:0]  exu_exres_r    ;
  logic  [`CPU_WIDTH-1:0]  exu_rs2_r      ;
  logic  [2:0]             exu_lsfunc3_r  ;
  logic                    exu_lden_r     ;
  logic                    exu_sten_r     ;
  logic  [`REG_ADDRW-1:0]  exu_rdid_r     ;
  logic                    exu_rdwen_r    ;
  logic  [`CSR_ADDRW-1:0]  exu_csrdid_r   ;
  logic                    exu_csrdwen_r  ;
  logic  [`CPU_WIDTH-1:0]  exu_csrd_r     ;
  logic  [`CPU_WIDTH-1:0]  exu_pc_r       ;
  logic                    exu_ecall_r    ;
  logic                    exu_mret_r     ;
  logic                    exu_nop_r      ;
  logic  [`INS_WIDTH-1:0]  exu_ins_r      ;

  stl_reg #(
    .WIDTH      (4*`CPU_WIDTH+`REG_ADDRW+`CSR_ADDRW+11+`INS_WIDTH),
    .RESET_VAL  (0       )
  ) prereg (
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (i_flush | pre_sh ),
    .i_din      (i_flush ? 0: {i_exu_exres, i_exu_rs2, i_exu_lsfunc3, i_exu_lden, i_exu_sten, i_exu_rdid, i_exu_rdwen, i_exu_fencei, i_exu_csrdid, i_exu_csrdwen, i_exu_csrd, i_exu_pc, i_exu_ecall, i_exu_mret, i_exu_nop, s_exu_ins} ),
    .o_dout     (             {exu_exres_r, exu_rs2_r, exu_lsfunc3_r, exu_lden_r, exu_sten_r, exu_rdid_r, exu_rdwen_r, exu_fencei_r, exu_csrdid_r, exu_csrdwen_r, exu_csrd_r, exu_pc_r, exu_ecall_r, exu_mret_r, exu_nop_r, exu_ins_r} )
  );

  // 2. deal with device :///////////////////////////////////////////////////////////////////////////////////////

  wire load_en, stor_en, en_clint;
  wire [`ADR_WIDTH-1:0] lsu_addr;

  assign load_en  = pre_valid_r & exu_lden_r;
  assign stor_en  = pre_valid_r & exu_sten_r;
  assign ldst_en  = load_en | stor_en ;
  assign lsu_addr = exu_exres_r[`ADR_WIDTH-1:0];

  // `CLINT_BASE_ADDR == 32'h02000000, `CLINT_END_ADDR == 32'h0200ffff
  assign en_clint = (lsu_addr & {{(`ADR_WIDTH-16){1'b1}},16'b0}) == `CLINT_BASE_ADDR;
  assign en_axi   = !en_clint;

  // 3. deal with clint :///////////////////////////////////////////////////////////////////////////////////////

  assign o_clint_ren    = en_clint & load_en;
  assign o_clint_raddr  = lsu_addr  ;

  assign o_clint_wen    = en_clint & stor_en;
  assign o_clint_waddr  = lsu_addr  ;
  assign o_clint_wdata  = exu_rs2_r ;

  // 4. use interface to read/write, generate valid signals for post stage:////////////////////////////////////

  assign dCacheIf_M.valid  = (exu_fencei_r | en_axi & ldst_en) & ~(i_iru_excp | i_iru_intr);
  assign dCacheIf_M.reqtyp = stor_en           ;
  assign dCacheIf_M.addr   = lsu_addr          ;
  assign dCacheIf_M.wdata  = exu_rs2_r         ;
  assign dCacheIf_M.size   = exu_lsfunc3_r[1:0];

  logic [`CPU_WIDTH-1:0] dCache_rdata;
  
  stl_mux_default #(7, 3, `CPU_WIDTH) mux_rdata (dCache_rdata, exu_lsfunc3_r, `CPU_WIDTH'b0, {
    `FUNC3_LB_SB, {{56{dCacheIf_M.rdata[ 7]}}, dCacheIf_M.rdata[ 7:0]},
    `FUNC3_LH_SH, {{48{dCacheIf_M.rdata[15]}}, dCacheIf_M.rdata[15:0]},
    `FUNC3_LW_SW, {{32{dCacheIf_M.rdata[31]}}, dCacheIf_M.rdata[31:0]},
    `FUNC3_LD_SD, dCacheIf_M.rdata                                    ,
    `FUNC3_LBU  , {56'b0, dCacheIf_M.rdata[ 7:0]}                     ,
    `FUNC3_LHU  , {48'b0, dCacheIf_M.rdata[15:0]}                     ,
    `FUNC3_LWU  , {32'b0, dCacheIf_M.rdata[31:0]}                     
  });

  // 5. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////

  assign o_lsu_lsres   = en_clint ? i_clint_rdata : dCache_rdata;
  assign o_lsu_exres   = exu_exres_r  ;
  assign o_lsu_lden    = exu_lden_r   ;
  assign o_lsu_fencei  = exu_fencei_r ;
  assign o_lsu_rdid    = exu_rdid_r   ;
  assign o_lsu_rdwen   = exu_rdwen_r  & pre_valid_r; // &pre_valid_r is used for bypass, to indicate lsu is valid.
  assign o_lsu_csrdid  = exu_csrdid_r ;
  assign o_lsu_csrdwen = exu_csrdwen_r& pre_valid_r; // &pre_valid_r is used for bypass, to indicate lsu is valid.
  assign o_lsu_csrd    = exu_csrd_r   ;
  assign o_lsu_pc      = exu_pc_r     ;
  assign o_lsu_ecall   = exu_ecall_r  ;
  assign o_lsu_mret    = exu_mret_r   ;
  assign o_lsu_nop     = exu_nop_r    ;
  assign s_lsu_ins     = exu_ins_r    ;
  assign s_lsu_lsclint = ldst_en & en_clint;
  assign s_lsu_device  = ldst_en & !lsu_addr[31];

endmodule
