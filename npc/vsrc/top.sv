`include "config.sv"
module top(
  input  logic                      i_clk           ,
  input  logic                      i_rst_n         ,
  // aw:
  input  logic                      i_axi_aw_ready  ,         
  output logic                      o_axi_aw_valid  ,
  output logic [`CPU_WIDTH-1:0]     o_axi_aw_addr   ,
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
  output logic [`CPU_WIDTH-1:0]     o_axi_ar_addr   ,
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

  uni_if #(.ADDR_W(`CPU_WIDTH), .DATA_W(`CPU_WIDTH)) ifu_uni_if();
  uni_if #(.ADDR_W(`CPU_WIDTH), .DATA_W(`CPU_WIDTH)) lsu_uni_if();

  core_top u_core_top(
    .i_clk       (i_clk       ),
    .i_rst_n     (rst_n_sync  ),
    .UniIf_ifu_M (ifu_uni_if  ),
    .UniIf_lsu_M (lsu_uni_if  )
  );

  // 3.arbite uni if://////////////////////////////////////////////
  logic uniID;  // 1: lsu uni if, 0: ifu uni if. 

  always_ff @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
      uniID <= 1'b0;
    end
    else if(lsu_uni_if.valid & lsu_uni_if.ready)begin
      uniID <= 1'b0;
    end
    else if(ifu_uni_if.valid & ifu_uni_if.ready & lsu_uni_if.valid)begin
      uniID <= 1'b1;
    end
  end

  uni_if #(.ADDR_W(`CPU_WIDTH), .DATA_W(`CPU_WIDTH)) uni_if();

  assign uni_if.valid  = uniID ? lsu_uni_if.valid  : ifu_uni_if.valid ;
  assign uni_if.reqtyp = uniID ? lsu_uni_if.reqtyp : ifu_uni_if.reqtyp;
  assign uni_if.addr   = uniID ? lsu_uni_if.addr   : ifu_uni_if.addr  ;
  assign uni_if.wdata  = uniID ? lsu_uni_if.wdata  : ifu_uni_if.wdata ;
  assign uni_if.size   = uniID ? lsu_uni_if.size   : ifu_uni_if.size  ;

  assign lsu_uni_if.ready = uniID ? uni_if.ready : 0;
  assign lsu_uni_if.rdata = uniID ? uni_if.rdata : 0;
  assign lsu_uni_if.resp  = uniID ? uni_if.resp  : 0;

  assign ifu_uni_if.ready = uniID ? 0 : uni_if.ready;
  assign ifu_uni_if.rdata = uniID ? 0 : uni_if.rdata;
  assign ifu_uni_if.resp  = uniID ? 0 : uni_if.resp ;

  // 4.uni_if 2 axi_if : //////////////////////////////////////////

  axi4_if #(.ADDR_W(`CPU_WIDTH), .DATA_W(`CPU_WIDTH), .ID_W(4), .USER_W(1)) axi_if();

  uni2axi #(
    .UNI_ADDR_WIDTH (`CPU_WIDTH ),
    .UNI_DATA_WIDTH (`CPU_WIDTH ),
    .AXI_ADDR_WIDTH (`CPU_WIDTH ),
    .AXI_DATA_WIDTH (`CPU_WIDTH ),
    .AXI_ID_WIDTH   (4          ),
    .AXI_USER_WIDTH (1          )
  ) u_uni2axi (
    .i_clk   (i_clk     ),
    .i_rst_n (rst_n_sync),
    .UniIf_S (uni_if    ),
    .AxiIf_M (axi_if    )
  );

  // 5. assign axi_if to wrapper://///////////////////////////////

  assign axi_if.aw_ready = i_axi_aw_ready   ;
  assign o_axi_aw_valid  = axi_if.aw_valid  ;
  assign o_axi_aw_addr   = axi_if.aw_addr   ;
  assign o_axi_aw_prot   = axi_if.aw_prot   ;
  assign o_axi_aw_id     = axi_if.aw_id     ;
  assign o_axi_aw_user   = axi_if.aw_user   ;
  assign o_axi_aw_len    = axi_if.aw_len    ;
  assign o_axi_aw_size   = axi_if.aw_size   ;
  assign o_axi_aw_burst  = axi_if.aw_burst  ;
  assign o_axi_aw_lock   = axi_if.aw_lock   ;
  assign o_axi_aw_cache  = axi_if.aw_cache  ;
  assign o_axi_aw_qos    = axi_if.aw_qos    ;
  assign o_axi_aw_region = axi_if.aw_region ;

  assign axi_if.w_ready  = i_axi_w_ready    ;
  assign o_axi_w_valid   = axi_if.w_valid   ;
  assign o_axi_w_data    = axi_if.w_data    ;
  assign o_axi_w_strb    = axi_if.w_strb    ;
  assign o_axi_w_last    = axi_if.w_last    ;
  assign o_axi_w_user    = axi_if.w_user    ;

  assign o_axi_b_ready   = axi_if.b_ready   ;
  assign axi_if.b_valid  = i_axi_b_valid    ;
  assign axi_if.b_resp   = i_axi_b_resp     ;
  assign axi_if.b_id     = i_axi_b_id       ;
  assign axi_if.b_user   = i_axi_b_user     ;

  assign axi_if.ar_ready = i_axi_ar_ready   ;
  assign o_axi_ar_valid  = axi_if.ar_valid  ;
  assign o_axi_ar_addr   = axi_if.ar_addr   ;
  assign o_axi_ar_prot   = axi_if.ar_prot   ;
  assign o_axi_ar_id     = axi_if.ar_id     ;
  assign o_axi_ar_user   = axi_if.ar_user   ;
  assign o_axi_ar_len    = axi_if.ar_len    ;
  assign o_axi_ar_size   = axi_if.ar_size   ;
  assign o_axi_ar_burst  = axi_if.ar_burst  ;
  assign o_axi_ar_lock   = axi_if.ar_lock   ;
  assign o_axi_ar_cache  = axi_if.ar_cache  ;
  assign o_axi_ar_qos    = axi_if.ar_qos    ;
  assign o_axi_ar_region = axi_if.ar_region ;

  assign o_axi_r_ready   = axi_if.r_ready   ;
  assign axi_if.r_valid  = i_axi_r_valid    ;
  assign axi_if.r_resp   = i_axi_r_resp     ;
  assign axi_if.r_data   = i_axi_r_data     ;
  assign axi_if.r_last   = i_axi_r_last     ;
  assign axi_if.r_id     = i_axi_r_id       ;
  assign axi_if.r_user   = i_axi_r_user     ;


endmodule
