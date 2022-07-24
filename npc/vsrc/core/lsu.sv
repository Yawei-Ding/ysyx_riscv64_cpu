module lsu (
  input                         i_clk         ,
  input                         i_rst_n       ,
  
  // 1. axi interface to get data from mem:
  uni_if.Master                 UniIf_M       ,

  // 2. signal to pipe shake hands:
  input                         i_pre_valid   ,   // from pre-stage
  output                        o_pre_ready   ,   //  to  pre-stage
  output                        o_post_valid  ,   //  to  post-stage
  input                         i_post_ready  ,   // from post-stage

  // 3. input comb signal from pre stage:
  input   [`CPU_WIDTH-1:0]      i_exu_exres   ,
  input   [`CPU_WIDTH-1:0]      i_exu_rs2     ,
  input   [`REG_ADDRW-1:0]      i_exu_rdid    ,
  input                         i_exu_rdwen   ,
  input   [2:0]                 i_exu_lsfunc3 ,
  input                         i_exu_lden    ,
  input                         i_exu_sten    ,
  input   [`CPU_WIDTH-1:0]      s_exu_diffpc  ,
  input   [`INS_WIDTH-1:0]      s_exu_ins     ,
  
  // 4. output comb signal to post stage:
  output  [`CPU_WIDTH-1:0]      o_lsu_lsres   ,
  output  [`CPU_WIDTH-1:0]      o_lsu_exres   ,
  output                        o_lsu_lden    ,
  output  [`REG_ADDRW-1:0]      o_lsu_rdid    ,
  output                        o_lsu_rdwen   ,
  // 5 for sim:
  output  [`CPU_WIDTH-1:0]      s_lsu_diffpc  ,
  output  [`INS_WIDTH-1:0]      s_lsu_ins     ,
  output                        s_lsu_device   //  1: write/read device, 0: no use device.
);

  // 1. shake hands to reg pre stage signals:////////////////////////////////s/////////////////////////////////

  // i_pre_valid --> ⌈‾‾‾‾⌉ --> o_post_valid
  //                 |REG|
  // o_pre_ready <-- ⌊____⌋ <-- i_post_ready

  assign o_pre_ready =  ldst_en ? (o_post_valid & i_post_ready) : (o_post_valid & i_post_ready | !o_post_valid) ;
  wire pre_sh = i_pre_valid & o_pre_ready;
  wire pre_valid_r;

  stl_reg #(
    .WIDTH      (1           ), 
    .RESET_VAL  (0           )
  ) postvalid (
  	.i_clk      (i_clk       ), 
    .i_rst_n    (i_rst_n     ), 
    .i_wen      (o_pre_ready ), 
    .i_din      (i_pre_valid ), 
    .o_dout     (pre_valid_r )
  );
  
  assign o_post_valid   = ldst_en ? UniIf_M.ready : pre_valid_r;

  logic  [`CPU_WIDTH-1:0]  exu_exres_r    ;
  logic  [`CPU_WIDTH-1:0]  exu_rs2_r      ;
  logic  [`REG_ADDRW-1:0]  exu_rdid_r     ;
  logic                    exu_rdwen_r    ;
  logic  [2:0]             exu_lsfunc3_r  ;
  logic                    exu_lden_r     ;
  logic                    exu_sten_r     ;
  logic  [`CPU_WIDTH-1:0]  exu_diffpc_r   ;
  logic  [`INS_WIDTH-1:0]  exu_ins_r      ;

  stl_reg #(
    .WIDTH      (3*`CPU_WIDTH+`REG_ADDRW+6+`INS_WIDTH),
    .RESET_VAL  (0       )
  ) prereg (
  	.i_clk      (i_clk   ),
    .i_rst_n    (i_rst_n ),
    .i_wen      (pre_sh ),
    .i_din      ({i_exu_exres, i_exu_rs2, i_exu_rdid, i_exu_rdwen, i_exu_lsfunc3, i_exu_lden, i_exu_sten, s_exu_diffpc,s_exu_ins} ),
    .o_dout     ({exu_exres_r, exu_rs2_r, exu_rdid_r, exu_rdwen_r, exu_lsfunc3_r, exu_lden_r, exu_sten_r, exu_diffpc_r,exu_ins_r} )
  );

  // 2. use interface to read/write, generate valid signals for post stage:////////////////////////////////////

  wire load_en = pre_valid_r & exu_lden_r;
  wire stor_en = pre_valid_r & exu_sten_r;
  wire ldst_en = load_en | stor_en ;

  assign UniIf_M.valid  = ldst_en ;
  assign UniIf_M.reqtyp = stor_en ; 
  assign UniIf_M.addr   = ldst_en ? exu_exres_r : `CPU_WIDTH'b0;
  assign UniIf_M.wdata  = stor_en ? exu_rs2_r   : `CPU_WIDTH'b0;

  stl_mux_default #(7, 3, 2) mux_size (UniIf_M.size, exu_lsfunc3_r, 2'b00, {
    `FUNC3_LB_SB, ldst_en ? 2'b00 : 2'b00, // load + store.
    `FUNC3_LH_SH, ldst_en ? 2'b01 : 2'b00, // load + store.
    `FUNC3_LW_SW, ldst_en ? 2'b10 : 2'b00, // load + store.
    `FUNC3_LD_SD, ldst_en ? 2'b11 : 2'b00, // load + store.
    `FUNC3_LBU  , load_en ? 2'b00 : 2'b00, // only load.
    `FUNC3_LHU  , load_en ? 2'b01 : 2'b00, // only load.
    `FUNC3_LWU  , load_en ? 2'b10 : 2'b00  // only load.
  });

  // 3. use one register to save data, which is must keep for bypass ://///////////////////////////////////////
  // think about this situation: 
  // ins1 in lsu is loading data,
  // ins2 in exu is calculate division.
  // ins3 in idu, and the rs1id or rs2id == rdid(ins1).
  // so the ins1 load data in lsu must be kept, until pre stage is fire (div is done).  

  logic [`CPU_WIDTH-1:0] unif_rdata,unif_rdata_r;
  stl_mux_default #(7, 3, `CPU_WIDTH) mux_rdata (unif_rdata, exu_lsfunc3_r, `CPU_WIDTH'b0, {
    `FUNC3_LB_SB, load_en ? {{56{UniIf_M.rdata[ 7]}}, UniIf_M.rdata[ 7:0]} : `CPU_WIDTH'b0 ,
    `FUNC3_LH_SH, load_en ? {{48{UniIf_M.rdata[15]}}, UniIf_M.rdata[15:0]} : `CPU_WIDTH'b0 ,
    `FUNC3_LW_SW, load_en ? {{32{UniIf_M.rdata[31]}}, UniIf_M.rdata[31:0]} : `CPU_WIDTH'b0 ,
    `FUNC3_LD_SD, load_en ? UniIf_M.rdata                                  : `CPU_WIDTH'b0 ,
    `FUNC3_LBU  , load_en ? {56'b0, UniIf_M.rdata[ 7:0]}                   : `CPU_WIDTH'b0 ,
    `FUNC3_LHU  , load_en ? {48'b0, UniIf_M.rdata[15:0]}                   : `CPU_WIDTH'b0 ,
    `FUNC3_LWU  , load_en ? {32'b0, UniIf_M.rdata[31:0]}                   : `CPU_WIDTH'b0 
  });

  wire UniIf_Sh = UniIf_M.valid & UniIf_M.ready;

  stl_reg #(
    .WIDTH      (`CPU_WIDTH   ),
    .RESET_VAL  (`CPU_WIDTH'b0)
  ) rdatareg (
  	.i_clk      (i_clk        ),
    .i_rst_n    (i_rst_n      ),
    .i_wen      (UniIf_Sh     ),
    .i_din      (unif_rdata   ),
    .o_dout     (unif_rdata_r )
  );

  assign  o_lsu_lsres  = UniIf_Sh ? unif_rdata : unif_rdata_r;

  // remind: due to the ready signal of post stage never be 0, so it is not necessary to keep the handshake of UniIf_M.

  // 4. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////
  assign  o_lsu_exres  = exu_exres_r  ;
  assign  o_lsu_lden   = exu_lden_r   ;
  assign  o_lsu_rdid   = exu_rdid_r   ;
  assign  o_lsu_rdwen  = exu_rdwen_r  ;
  assign  s_lsu_diffpc = exu_diffpc_r ;
  assign  s_lsu_ins    = exu_ins_r    ;
  assign  s_lsu_device = (UniIf_M.addr >= `CPU_WIDTH'h10000000 & UniIf_M.addr <= `CPU_WIDTH'h10000fff);

endmodule
