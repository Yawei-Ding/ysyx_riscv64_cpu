`include "defines.sv"
module uni2axi # (
    parameter UNI_ADDR_WIDTH    = 32,                   // addr width for uni if
    parameter UNI_DATA_WIDTH    = 128,                  // data width for uni if
    parameter AXI_ADDR_WIDTH    = 32,                   // addr width for axi if
    parameter AXI_DATA_WIDTH    = 64,                   // data width for axi if
    parameter AXI_STRB_WIDTH    = AXI_DATA_WIDTH/8,     // strb width for axi if
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_USER_WIDTH    = 1
)(
  input                               i_clk   ,
  input                               i_rst_n ,
  uni_if.Slave                        UniIf_S ,
  axi4_if.Master                      AxiIf_M
);

  wire w_trans    = UniIf_S.reqtyp == `REQ_WRITE;
  wire r_trans    = UniIf_S.reqtyp == `REQ_READ ;
  wire w_valid    = UniIf_S.valid & w_trans;
  wire r_valid    = UniIf_S.valid & r_trans;

  // handshake
  wire aw_hs      = AxiIf_M.aw_valid & AxiIf_M.aw_ready;
  wire w_hs       = AxiIf_M.w_valid  & AxiIf_M.w_ready ;
  wire b_hs       = AxiIf_M.b_valid  & AxiIf_M.b_ready ;
  wire ar_hs      = AxiIf_M.ar_valid & AxiIf_M.ar_ready;
  wire r_hs       = AxiIf_M.r_valid  & AxiIf_M.r_ready ;

  wire w_done     = w_hs & AxiIf_M.w_last;
  wire r_done     = r_hs & AxiIf_M.r_last;
  wire trans_done = w_trans ? b_hs : r_done;

  // ------------------State Machine------------------
  localparam [1:0] W_STATE_IDLE = 2'b00, W_STATE_ADDR = 2'b01, W_STATE_WRITE = 2'b10, W_STATE_RESP = 2'b11;
  localparam [1:0] R_STATE_IDLE = 2'b00, R_STATE_ADDR = 2'b01, R_STATE_READ  = 2'b10;

  reg [1:0] w_state, r_state;
  wire w_state_idle = w_state == W_STATE_IDLE, w_state_addr = w_state == W_STATE_ADDR, w_state_write = w_state == W_STATE_WRITE, w_state_resp = w_state == W_STATE_RESP;
  wire r_state_idle = r_state == R_STATE_IDLE, r_state_addr = r_state == R_STATE_ADDR, r_state_read  = r_state == R_STATE_READ;

  // Wirte State Machine
  always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
          w_state <= W_STATE_IDLE;
      end
      else begin
          if (w_valid) begin
              case (w_state)
                  W_STATE_IDLE:               w_state <= W_STATE_ADDR;
                  W_STATE_ADDR:  if (aw_hs)   w_state <= W_STATE_WRITE;
                  W_STATE_WRITE: if (w_done)  w_state <= W_STATE_RESP;
                  W_STATE_RESP:  if (b_hs)    w_state <= W_STATE_IDLE;
              endcase
          end
      end
  end

  // Read State Machine
  always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
          r_state <= R_STATE_IDLE;
      end
      else begin
          if (r_valid) begin
              case (r_state)
                  R_STATE_IDLE:               r_state <= R_STATE_ADDR;
                  R_STATE_ADDR: if (ar_hs)    r_state <= R_STATE_READ;
                  R_STATE_READ: if (r_done)   r_state <= R_STATE_IDLE;
                  default:;
              endcase
          end
      end
  end

  // ------------------Number of transmission------------------
  logic [7:0] len, axi_len;
  always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
          len <= 0;
      end else if ((w_trans & w_state_idle) | (r_trans & r_state_idle)) begin
          len <= 0;
      end else if ((len != axi_len) & (w_hs | r_hs)) begin    // axi_len == total write/read len.
          len <= len + 1;
      end
  end

  // ------------------Process Data------------------
  localparam TRANS_LEN = UNI_DATA_WIDTH / AXI_DATA_WIDTH;  // 2

  // for SoC:
  // wire                      is_uart  = (UniIf_S.addr & {{(`ADR_WIDTH-12){1'b1}},12'b0}) == `UART_BASE_ADDR;
  // wire [AXI_ADDR_WIDTH-1:0] axi_addr = {{(AXI_ADDR_WIDTH-UNI_ADDR_WIDTH){1'b0}},UniIf_S.addr[UNI_ADDR_WIDTH-1:2], is_uart ? UniIf_S.addr[1:0]: 2'b00}; // for SoC

  // for soc-simulator: 
  wire [AXI_ADDR_WIDTH-1:0] axi_addr = {{(AXI_ADDR_WIDTH-UNI_ADDR_WIDTH){1'b0}},UniIf_S.addr[UNI_ADDR_WIDTH-1:2], 2'b00};

  wire [1:0] offset   = UniIf_S.addr[1:0];
  wire [2:0] axi_size = {1'b0,UniIf_S.size};

  wire        size_b  = (UniIf_S.size == 2'b00);
  wire        size_h  = (UniIf_S.size == 2'b01);
  wire        size_w  = (UniIf_S.size == 2'b10);

  wire [AXI_STRB_WIDTH-1:0] dev_strb = (({AXI_STRB_WIDTH{size_b}} & {8'b0000_0001})
                                      | ({AXI_STRB_WIDTH{size_h}} & {8'b0000_0011})
                                      | ({AXI_STRB_WIDTH{size_w}} & {8'b0000_1111})) << offset;

  assign                    axi_len  = UniIf_S.cachable ? (TRANS_LEN - 1) : 0;

  wire [AXI_ID_WIDTH-1:0]   axi_id   = {AXI_ID_WIDTH{1'b0}};
  wire [AXI_USER_WIDTH-1:0] axi_user = {AXI_USER_WIDTH{1'b0}};

  always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
          UniIf_S.ready <= 0;
      end
      else if (trans_done | UniIf_S.ready) begin
          UniIf_S.ready <= trans_done;
      end
  end

  // ------------------Write Transaction------------------

  // write addr channel:
  assign AxiIf_M.aw_valid   = w_state_addr & w_valid;
  assign AxiIf_M.aw_addr    = axi_addr;
  assign AxiIf_M.aw_len     = axi_len;
  assign AxiIf_M.aw_size    = axi_size;
  assign AxiIf_M.aw_burst   = `AXI_BURST_TYPE_INCR;
  assign AxiIf_M.aw_id      = axi_id;                                                                           // no use.
  assign AxiIf_M.aw_user    = axi_user;                                                                         // no use.
  assign AxiIf_M.aw_prot    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;  // no use.
  assign AxiIf_M.aw_cache   = `AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE;                                  // no use.
  assign AxiIf_M.aw_lock    = 1'b0;                                                                             // no use.
  assign AxiIf_M.aw_qos     = 4'h0;                                                                             // no use.
  assign AxiIf_M.aw_region  = 4'h0;                                                                             // no use.

  // write response channel:
  assign AxiIf_M.b_ready    = w_state_resp;

  // write data channel:
  assign AxiIf_M.w_valid    = w_state_write;
  assign AxiIf_M.w_last     = w_hs & (len == axi_len);
  assign AxiIf_M.w_user     = axi_user;                                                                         // no use.
  assign AxiIf_M.w_strb     = UniIf_S.cachable ? {AXI_STRB_WIDTH{1'b1}} : dev_strb;
  assign AxiIf_M.w_data     = UniIf_S.wdata[len*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] << {offset,3'b0};

  // ------------------Read Transaction------------------

  // Read address channel signals
  assign AxiIf_M.ar_valid   = r_state_addr & r_valid;
  assign AxiIf_M.ar_addr    = axi_addr;
  assign AxiIf_M.ar_prot    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;
  assign AxiIf_M.ar_id      = axi_id;
  assign AxiIf_M.ar_user    = axi_user;
  assign AxiIf_M.ar_len     = axi_len;
  assign AxiIf_M.ar_size    = axi_size;
  assign AxiIf_M.ar_burst   = `AXI_BURST_TYPE_INCR;
  assign AxiIf_M.ar_lock    = 1'b0;
  assign AxiIf_M.ar_cache   = `AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;
  assign AxiIf_M.ar_qos     = 4'h0;

  // Read data channel signals
  assign AxiIf_M.r_ready    = r_state_read;

  for(genvar i=0; i<TRANS_LEN; i=i+1)begin
    always @(posedge i_clk or negedge i_rst_n) begin
      if (!i_rst_n) begin
        UniIf_S.rdata[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= 0;
      end else if (AxiIf_M.r_valid & AxiIf_M.r_ready & (i==len)) begin
        UniIf_S.rdata[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= (AxiIf_M.r_data >> {offset,3'b0});
      end
    end
  end

endmodule
