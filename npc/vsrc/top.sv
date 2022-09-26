`include "defines.sv"
module top(
  input  logic                      i_clk           ,
  input  logic                      i_rst_n         ,
  // aw:
  input  logic                      i_axi_aw_ready  ,
  output logic                      o_axi_aw_valid  ,
  output logic [`ADR_WIDTH-1:0]     o_axi_aw_addr   ,
  output logic [2:0]                o_axi_aw_prot   ,
  output logic [3:0]                o_axi_aw_id     ,
  output logic                      o_axi_aw_user   ,
  output logic [7:0]                o_axi_aw_len    ,
  output logic [2:0]                o_axi_aw_size   ,
  output logic [1:0]                o_axi_aw_burst  ,
  output logic                      o_axi_aw_lock   ,
  output logic [3:0]                o_axi_aw_cache  ,
  output logic [3:0]                o_axi_aw_qos    ,
  output logic [3:0]                o_axi_aw_region ,
  // w:
  input  logic                      i_axi_w_ready   ,
  output logic                      o_axi_w_valid   ,
  output logic [`CPU_WIDTH-1:0]     o_axi_w_data    ,
  output logic [`CPU_WIDTH/8-1:0]   o_axi_w_strb    ,
  output logic                      o_axi_w_last    ,
  output logic                      o_axi_w_user    ,
  // b:
  output logic                      o_axi_b_ready   ,
  input  logic                      i_axi_b_valid   ,
  input  logic [1:0]                i_axi_b_resp    ,
  input  logic [3:0]                i_axi_b_id      ,
  input  logic                      i_axi_b_user    ,
  // ar:
  input  logic                      i_axi_ar_ready  ,
  output logic                      o_axi_ar_valid  ,
  output logic [`ADR_WIDTH-1:0]     o_axi_ar_addr   ,
  output logic [2:0]                o_axi_ar_prot   ,
  output logic [3:0]                o_axi_ar_id     ,
  output logic                      o_axi_ar_user   ,
  output logic [7:0]                o_axi_ar_len    ,
  output logic [2:0]                o_axi_ar_size   ,
  output logic [1:0]                o_axi_ar_burst  ,
  output logic                      o_axi_ar_lock   ,
  output logic [3:0]                o_axi_ar_cache  ,
  output logic [3:0]                o_axi_ar_qos    ,
  output logic [3:0]                o_axi_ar_region ,
  // r:
  output logic                      o_axi_r_ready   ,
  input  logic                      i_axi_r_valid   ,
  input  logic [1:0]                i_axi_r_resp    ,
  input  logic [`CPU_WIDTH-1:0]     i_axi_r_data    ,
  input  logic                      i_axi_r_last    ,
  input  logic [3:0]                i_axi_r_id      ,
  input  logic                      i_axi_r_user
);

  // 1.rst : ////////////////////////////////////////////////////////
  logic rst_n_sync;
  stl_rst u_stl_rst(
  	.i_clk        (i_clk      ),
    .i_rst_n      (i_rst_n    ),
    .o_rst_n_sync (rst_n_sync )
  );

  // 2.cpu core:///////////////////////////////////////////////////
  logic invalidIChe, cleanDChe;
  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(`INS_WIDTH)) iCacheIf();  // 32bit, ins.
  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(`CPU_WIDTH)) dCacheIf();  // 64bit, data.

  core_top u_core_top(
    .i_clk            (i_clk            ),
    .i_rst_n          (rst_n_sync       ),
    .iCacheIf_M       (iCacheIf         ),
    .dCacheIf_M       (dCacheIf         ),
    .o_invalidIChe    (invalidIChe      ),
    .o_cleanDChe      (cleanDChe        )
  );

  // 3.cache: /////////////////////////////////////////////////////
  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(128)) dMemIf();
  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(128)) iMemIf();

  iCache_wrapper u_iCache_wrapper(
    .i_clk      (i_clk        ),
    .i_rst_n    (rst_n_sync   ),
    .i_invalid  (invalidIChe  ),
    .iCacheIf_S (iCacheIf     ),
    .iMemIf_M   (iMemIf       )
  );

  dCache_wrapper u_dCache_wrapper(
    .i_clk      (i_clk      ),
    .i_rst_n    (rst_n_sync ),
    .i_clean    (cleanDChe  ),
    .dCacheIf_S (dCacheIf   ),
    .dMemIf_M   (dMemIf     )
  );

  // 4.arbite UniIf://////////////////////////////////////////////
  logic uniID;  // 1: dMemIf, 0: iMemIf. 

  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(128)) UniIf();

  wire dMemIfFree = dMemIf.valid & dMemIf.ready | !dMemIf.valid;
  wire iMemIfFree = iMemIf.valid & iMemIf.ready | !iMemIf.valid;

  stl_reg #(
    .WIDTH      (1   ),                                                                  // always_ff @(posedge i_clk or negedge i_rst_n) begin
    .RESET_VAL  (1'b0)                                                                   //   if(!i_rst_n)begin
  ) reg_unid (                                                                           //     uniID <= 1'b0;
  	.i_clk      (i_clk      ),                                                           //   end else if(dMemIf.valid & iMemIfFree)begin
    .i_rst_n    (rst_n_sync ),                                                  // <==>  //     uniID <= 1'b1;
    .i_wen      ((iMemIf.valid & dMemIfFree) | (dMemIf.valid & iMemIfFree)),             //   end else if(iMemIf.valid & dMemIfFree)begin
    .i_din      ((dMemIf.valid & iMemIfFree)),                                           //     uniID <= 1'b0;
    .o_dout     (uniID      )                                                            //   end
  );                                                                                     // end

  assign UniIf.valid    = uniID ? dMemIf.valid    : iMemIf.valid    ;
  assign UniIf.reqtyp   = uniID ? dMemIf.reqtyp   : iMemIf.reqtyp   ;
  assign UniIf.addr     = uniID ? dMemIf.addr     : iMemIf.addr     ;
  assign UniIf.wdata    = uniID ? dMemIf.wdata    : iMemIf.wdata    ;
  assign UniIf.size     = uniID ? dMemIf.size     : iMemIf.size     ;
  assign UniIf.cachable = uniID ? dMemIf.cachable : iMemIf.cachable ;

  assign dMemIf.ready   = uniID ? UniIf.ready : 0;
  assign dMemIf.rdata   = uniID ? UniIf.rdata : 0;

  assign iMemIf.ready   = uniID ? 0 : UniIf.ready;
  assign iMemIf.rdata   = uniID ? 0 : UniIf.rdata;

  // 5.UniIf 2 AxiIf : //////////////////////////////////////////

  axi4_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(`CPU_WIDTH), .ID_W(4), .USER_W(1)) AxiIf();

  uni2axi #(
    .UNI_ADDR_WIDTH (`ADR_WIDTH ),
    .UNI_DATA_WIDTH (128        ),
    .AXI_ADDR_WIDTH (`ADR_WIDTH ),
    .AXI_DATA_WIDTH (`CPU_WIDTH ),
    .AXI_ID_WIDTH   (4          ),
    .AXI_USER_WIDTH (1          )
  ) u_uni2axi (
    .i_clk   (i_clk     ),
    .i_rst_n (rst_n_sync),
    .UniIf_S (UniIf     ),
    .AxiIf_M (AxiIf     )
  );

  // 6. assign AxiIf to wrapper://///////////////////////////////

  assign AxiIf.aw_ready  = i_axi_aw_ready  ;
  assign o_axi_aw_valid  = AxiIf.aw_valid  ;
  assign o_axi_aw_addr   = AxiIf.aw_addr   ;
  assign o_axi_aw_prot   = AxiIf.aw_prot   ;
  assign o_axi_aw_id     = AxiIf.aw_id     ;
  assign o_axi_aw_user   = AxiIf.aw_user   ;
  assign o_axi_aw_len    = AxiIf.aw_len    ;
  assign o_axi_aw_size   = AxiIf.aw_size   ;
  assign o_axi_aw_burst  = AxiIf.aw_burst  ;
  assign o_axi_aw_lock   = AxiIf.aw_lock   ;
  assign o_axi_aw_cache  = AxiIf.aw_cache  ;
  assign o_axi_aw_qos    = AxiIf.aw_qos    ;
  assign o_axi_aw_region = AxiIf.aw_region ;

  assign AxiIf.w_ready   = i_axi_w_ready   ;
  assign o_axi_w_valid   = AxiIf.w_valid   ;
  assign o_axi_w_data    = AxiIf.w_data    ;
  assign o_axi_w_strb    = AxiIf.w_strb    ;
  assign o_axi_w_last    = AxiIf.w_last    ;
  assign o_axi_w_user    = AxiIf.w_user    ;

  assign o_axi_b_ready   = AxiIf.b_ready   ;
  assign AxiIf.b_valid   = i_axi_b_valid   ;
  assign AxiIf.b_resp    = i_axi_b_resp    ;
  assign AxiIf.b_id      = i_axi_b_id      ;
  assign AxiIf.b_user    = i_axi_b_user    ;

  assign AxiIf.ar_ready  = i_axi_ar_ready  ;
  assign o_axi_ar_valid  = AxiIf.ar_valid  ;
  assign o_axi_ar_addr   = AxiIf.ar_addr   ;
  assign o_axi_ar_prot   = AxiIf.ar_prot   ;
  assign o_axi_ar_id     = AxiIf.ar_id     ;
  assign o_axi_ar_user   = AxiIf.ar_user   ;
  assign o_axi_ar_len    = AxiIf.ar_len    ;
  assign o_axi_ar_size   = AxiIf.ar_size   ;
  assign o_axi_ar_burst  = AxiIf.ar_burst  ;
  assign o_axi_ar_lock   = AxiIf.ar_lock   ;
  assign o_axi_ar_cache  = AxiIf.ar_cache  ;
  assign o_axi_ar_qos    = AxiIf.ar_qos    ;
  assign o_axi_ar_region = AxiIf.ar_region ;

  assign o_axi_r_ready   = AxiIf.r_ready   ;
  assign AxiIf.r_valid   = i_axi_r_valid   ;
  assign AxiIf.r_resp    = i_axi_r_resp    ;
  assign AxiIf.r_data    = i_axi_r_data    ;
  assign AxiIf.r_last    = i_axi_r_last    ;
  assign AxiIf.r_id      = i_axi_r_id      ;
  assign AxiIf.r_user    = i_axi_r_user    ;


endmodule
