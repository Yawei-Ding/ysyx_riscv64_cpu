
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

module uni2axi # (
    parameter UNI_ADDR_WIDTH    = 32,                   // addr width for uni if
    parameter UNI_DATA_WIDTH    = 64,                   // data width for uni if
    parameter AXI_ADDR_WIDTH    = 64,                   // addr width for axi if
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

  wire w_trans    = UniIf_S.reqtyp == 1'b1;
  wire r_trans    = UniIf_S.reqtyp == 1'b0;
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
  parameter [1:0] W_STATE_IDLE = 2'b00, W_STATE_ADDR = 2'b01, W_STATE_WRITE = 2'b10, W_STATE_RESP = 2'b11;
  parameter [1:0] R_STATE_IDLE = 2'b00, R_STATE_ADDR = 2'b01, R_STATE_READ  = 2'b10;

  reg [1:0] w_state, r_state;
  wire w_state_idle = w_state == W_STATE_IDLE, w_state_addr = w_state == W_STATE_ADDR, w_state_write = w_state == W_STATE_WRITE, w_state_resp = w_state == W_STATE_RESP;
  wire r_state_idle = r_state == R_STATE_IDLE, r_state_addr = r_state == R_STATE_ADDR, r_state_read  = r_state == R_STATE_READ;

  // Wirte State Machine
  always @(posedge i_clk) begin
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
  always @(posedge i_clk) begin
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
  reg [7:0] len;
  always @(posedge i_clk) begin
      if (!i_rst_n) begin
          len <= 0;
      end else if ((w_trans & w_state_idle) | (r_trans & r_state_idle)) begin
          len <= 0;
      end else if ((len != axi_len) & (w_hs | r_hs)) begin    // axi_len == total write/read len.
          len <= len + 1;
      end
  end

  // ------------------Process Data------------------
  parameter ALIGNED_WIDTH = $clog2(AXI_STRB_WIDTH);           // 3
  parameter OFFSET_WIDTH  = $clog2(AXI_DATA_WIDTH);           // 6
  parameter AXI_SIZE      = $clog2(AXI_STRB_WIDTH);           // 3
  parameter MASK_WIDTH    = AXI_DATA_WIDTH * 2;               // 128
  parameter TRANS_LEN     = UNI_DATA_WIDTH / AXI_DATA_WIDTH;  // 1
  parameter BLOCK_TRANS   = TRANS_LEN > 1 ? 1'b1 : 1'b0;      // 0

  wire aligned            = BLOCK_TRANS | (UniIf_S.addr[ALIGNED_WIDTH-1:0] == 0);
  wire size_b             = (UniIf_S.size == 2'b00);
  wire size_h             = (UniIf_S.size == 2'b01);
  wire size_w             = (UniIf_S.size == 2'b10);
  wire size_d             = (UniIf_S.size == 2'b11);
  wire [3:0] addr_op1     = {{(4-ALIGNED_WIDTH){1'b0}}, UniIf_S.addr[ALIGNED_WIDTH-1:0]};
  wire [3:0] addr_op2     = ({4{size_b}} & {4'b0000})     // byte
                          | ({4{size_h}} & {4'b0001})     // half byte
                          | ({4{size_w}} & {4'b0011})     // word
                          | ({4{size_d}} & {4'b0111});    // double word
  wire [3:0] addr_end     = addr_op1 + addr_op2;
  wire overstep           = addr_end[3:ALIGNED_WIDTH] != 0;

  wire [7:0] axi_len      = aligned ? TRANS_LEN - 1 : {{7{1'b0}}, overstep};
  wire [2:0] axi_size     = AXI_SIZE[2:0];

  wire [AXI_ADDR_WIDTH-1:0] axi_addr       = {UniIf_S.addr[AXI_ADDR_WIDTH-1:ALIGNED_WIDTH], {ALIGNED_WIDTH{1'b0}}};
  wire [OFFSET_WIDTH-1:0] aligned_offset_l = {{(OFFSET_WIDTH-ALIGNED_WIDTH){1'b0}}, {UniIf_S.addr[ALIGNED_WIDTH-1:0]}} << 3; // <<3 == *8
  wire [OFFSET_WIDTH-1:0] aligned_offset_h = AXI_DATA_WIDTH - aligned_offset_l;
  wire [MASK_WIDTH-1:0] mask               = (({MASK_WIDTH{size_b}} & {{(MASK_WIDTH-8 ){1'b0}}, 8'hff})
                                            | ({MASK_WIDTH{size_h}} & {{(MASK_WIDTH-16){1'b0}}, 16'hffff})
                                            | ({MASK_WIDTH{size_w}} & {{(MASK_WIDTH-32){1'b0}}, 32'hffffffff})
                                            | ({MASK_WIDTH{size_d}} & {{(MASK_WIDTH-64){1'b0}}, 64'hffffffff_ffffffff})
                                            ) << aligned_offset_l;
  wire [AXI_DATA_WIDTH-1:0] mask_l         = mask[AXI_DATA_WIDTH-1:0];
  wire [AXI_DATA_WIDTH-1:0] mask_h         = mask[MASK_WIDTH-1:AXI_DATA_WIDTH];

  wire [AXI_ID_WIDTH-1:0]   axi_id         = {AXI_ID_WIDTH{1'b0}};
  wire [AXI_USER_WIDTH-1:0] axi_user       = {AXI_USER_WIDTH{1'b0}};

  always @(posedge i_clk) begin
      if (!i_rst_n) begin
          UniIf_S.ready <= 0;
      end
      else if (trans_done | UniIf_S.ready) begin
          UniIf_S.ready <= trans_done;
      end
  end

  always @(posedge i_clk) begin
      if (!i_rst_n) begin
          UniIf_S.resp <= 0;
      end
      else if (trans_done) begin
          UniIf_S.resp <= w_trans ? AxiIf_M.b_resp : AxiIf_M.r_resp;
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
  wire [AXI_DATA_WIDTH-1:0] axi_w_data_l = (UniIf_S.wdata << aligned_offset_l) & mask_l;
  wire [AXI_DATA_WIDTH-1:0] axi_w_data_h = (UniIf_S.wdata >> aligned_offset_h) & mask_h;
  wire [AXI_STRB_WIDTH-1:0] axi_w_strb_l;
  wire [AXI_STRB_WIDTH-1:0] axi_w_strb_h;

  for(genvar i=0; i<AXI_STRB_WIDTH ; i=i+1)begin
      assign axi_w_strb_l[i] = mask_l[8*i];
      assign axi_w_strb_h[i] = mask_h[8*i];
  end

  // write only support uni_data_w == axi_data_w!
  assign AxiIf_M.w_data = AxiIf_M.w_valid ? ( (~aligned & overstep & len[0]) ? axi_w_data_h : axi_w_data_l): {AXI_DATA_WIDTH{1'b0}};
  assign AxiIf_M.w_strb = AxiIf_M.w_valid ? ( (~aligned & overstep & len[0]) ? axi_w_strb_h : axi_w_strb_l): {AXI_STRB_WIDTH{1'b0}};

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

  wire [AXI_DATA_WIDTH-1:0] axi_r_data_l  = (AxiIf_M.r_data & mask_l) >> aligned_offset_l;
  wire [AXI_DATA_WIDTH-1:0] axi_r_data_h  = (AxiIf_M.r_data & mask_h) << aligned_offset_h;

  generate
      for (genvar i = 0; i < TRANS_LEN; i = i+1) begin
          always @(posedge i_clk) begin
              if (!i_rst_n) begin
                  UniIf_S.rdata[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= 0;
              end
              else if (AxiIf_M.r_valid  & AxiIf_M.r_ready) begin
                  if (~aligned & overstep) begin
                      if (len[0]) begin   // second read.
                          UniIf_S.rdata[AXI_DATA_WIDTH-1:0] <= UniIf_S.rdata[AXI_DATA_WIDTH-1:0] | axi_r_data_h;
                      end
                      else begin          // first read.
                          UniIf_S.rdata[AXI_DATA_WIDTH-1:0] <= axi_r_data_l;
                      end
                  end
                  else if (len == i) begin
                      UniIf_S.rdata[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= axi_r_data_l;
                  end
              end
          end
      end
  endgenerate

endmodule
