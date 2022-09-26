`include "defines.sv"
module iCache (
  input                       i_clk     ,
  input                       i_rst_n   ,
  input                       i_invalid ,
  uni_if.Slave                iCacheIf_S,  //  32 bit width
  uni_if.Master               iMemIf_M     // 128 bit width
);

  //1. iCache : ////////////////////////////////////////////////////////////////////////////////////////////////////////////

  //          |<------16 bytes---->|                |<------16 bytes---->|
  //   ⌈‾‾‾‾‾⌉ ⌈‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾⌉         ⌈‾‾‾‾‾⌉ ⌈‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾⌉ ——
  //   |    | |                    |        |     | |                   |  ↑
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |Tag0| |    Cacheline0      |        |Tag1 | |    Cacheline1     |  |128 sets.
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  |
  //   |    | |                    |        |     | |                   |  ↓
  //   ⌊_____⌋ ⌊____________________⌋         ⌊_____⌋ ⌊____________________⌋ ——


  // tag array signal:
  logic                  tary_wen   [1:0];
  logic [6:0]            tary_addr  [1:0];
  logic [`iTARY_W-1:0]   tary_wdata [1:0];
  logic [`iTARY_W-1:0]   tary_rdata [1:0];

  // data array signal:
  logic                  dary_ren   [1:0];
  logic                  dary_wen   [1:0];
  logic [6:0]            dary_addr  [1:0];
  logic [15:0]           dary_wstrb [1:0];
  logic [127:0]          dary_wdata [1:0];
  logic [127:0]          dary_rdata [1:0];

  for (genvar i=0; i<2 ; i=i+1) begin
    iCache_tag_ary #(
      .DATA_WIDTH (`iTARY_W)
    ) u_tag_ary(
      .i_clk    (i_clk        ),
      .i_rst_n  (i_rst_n      ),
      .i_invalid(i_invalid    ),
      .i_wen    (tary_wen  [i]),
      .i_addr   (tary_addr [i]),
      .i_din    (tary_wdata[i]),
      .o_dout   (tary_rdata[i])
    );
    data_ary u_data_ary(
      .i_clk   (i_clk         ),
      .i_rst_n (i_rst_n       ),
      .i_ren   (dary_ren  [i] ),
      .i_wen   (dary_wen  [i] ),
      .i_wstrb (dary_wstrb[i] ),
      .i_addr  (dary_addr [i] ),
      .i_wdata (dary_wdata[i] ),
      .o_rdata (dary_rdata[i] )
    );
  end

  logic [127:0] recent, recent_wen;
  logic recent_wdata;

  for (genvar i=0; i<128 ; i=i+1) begin
    stl_reg #(
      .WIDTH      (1            ),
      .RESET_VAL  (1'b0         )
    ) reg_recent (
      .i_clk      (i_clk        ),
      .i_rst_n    (i_rst_n      ),
      .i_wen      (recent_wen[i]),
      .i_din      (recent_wdata ),
      .o_dout     (recent[i]    )
    );
  end


  // 2. control signals: ///////////////////////////////////////////////////////////////////////////////////////////////////
  wire [`TAG_BIT] tag    = iCacheIf_S.addr[`ADR_WIDTH-1:11];
  wire [6:0]      index  = iCacheIf_S.addr[ 10:4];
  wire [3:0]      offset = iCacheIf_S.addr[  3:0];

  wire [1:0] hit;
  for (genvar i=0; i<2 ; i=i+1) begin
    assign hit[i] = (tary_rdata[i][`TAG_BIT] == tag) & tary_rdata[i][`VLD_BIT];
  end

  wire victim_blkid = ~recent[index];
  
  // 3. state machine: /////////////////////////////////////////////////////////////////////////////////////////////////////

  enum logic[1:0] {IDLE, BUS, HIT} state;
  logic [1:0] ich_state, ich_state_n;

  stl_reg #(
    .WIDTH      (2          ),
    .RESET_VAL  (IDLE       )
  ) reg_status (
  	.i_clk      (i_clk      ),
    .i_rst_n    (i_rst_n    ),
    .i_wen      (1'b1       ),
    .i_din      (ich_state_n),
    .o_dout     (ich_state  )
  );

  always @(*) begin
    case (ich_state)
      IDLE:     if(iCacheIf_S.valid)begin
                  if(|hit)begin
                    ich_state_n = HIT;
                  end else begin
                    ich_state_n = BUS;
                  end
                end else begin
                  ich_state_n = IDLE;
                end
      BUS:      if(iMemIf_M.ready)
                  ich_state_n = IDLE;
                else
                  ich_state_n = BUS;
      HIT:      ich_state_n = IDLE;
      default:  ich_state_n = IDLE;
    endcase 
  end

  // 4. hit, read data array, update recent: /////////////////////////////////////////////////////////////////////////////////

  for (genvar i=0; i<128; i=i+1 ) begin
    assign recent_wen[i] = (ich_state == HIT) & (index == i);
  end

  assign recent_wdata = hit[1] ? 1'b1 : 1'b0;

  for (genvar i=0; i<2 ; i=i+1) begin
    assign dary_ren  [i] = (ich_state_n == HIT) & hit[i];
  end

  wire [127:0] hit_cacheline = hit[1] ? dary_rdata[1] : (hit[0] ? dary_rdata[0] : 128'b0);

  // 5. hit, iCacheIf_S signal: //////////////////////////////////////////////////////////////////////////////////////////////
  // input:  valid, addr, reqtyp(awlays `REQ_READ) , wdata(always 0), size(always 2'b10);
  // output: ready, rdata;

  assign iCacheIf_S.ready = (ich_state == HIT);

  stl_mux_default #(4, 4, `ADR_WIDTH) mux_size (iCacheIf_S.rdata, offset, {`ADR_WIDTH'b0}, {
    4'd0  , hit_cacheline[`ADR_WIDTH-1:0],
    4'd4  , hit_cacheline[`ADR_WIDTH-1+32:32],
    4'd8  , hit_cacheline[`ADR_WIDTH-1+64:64],
    4'd12 , hit_cacheline[`ADR_WIDTH-1+96:96]
  });

  // 6. iMemIf_M signal: ////////////////////////////////////////////////////////////////////////////////////////////////////
  // input:  ready, rdata;
  // output: valid, reqtyp(awlays `REQ_READ), addr, wdata(always 0), size(always 2'b11);

  assign iMemIf_M.valid  =  (ich_state == BUS);
  assign iMemIf_M.reqtyp =  `REQ_READ;
  assign iMemIf_M.addr   =  {tag,index,4'b0};
  assign iMemIf_M.wdata  =  128'b0;
  assign iMemIf_M.size   =  2'b11;

  // 7. update tag_arry & data_array:///////////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_wen    [i] = iMemIf_M.valid & iMemIf_M.ready & (i == victim_blkid);
    assign tary_addr   [i] = index;
    assign tary_wdata  [i] = {1'b1,tag};
    assign dary_wen    [i] = iMemIf_M.valid & iMemIf_M.ready & (i == victim_blkid);
    assign dary_addr   [i] = index;
    assign dary_wstrb  [i] = 16'hffff;
    assign dary_wdata  [i] = iMemIf_M.rdata;
  end

endmodule
