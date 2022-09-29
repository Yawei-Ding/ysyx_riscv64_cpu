`include "defines.sv"
module dCache (
  input                       i_clk     ,
  input                       i_rst_n   ,
  input                       i_clean   ,
  uni_if.Slave                dCacheIf_S,  //  64 bit width
  uni_if.Master               dMemIf_M     // 128 bit width
);

  //1. dCache : ////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

  logic [6:0]            cacheline_addr  ;

  // tag array signal:
  logic                  tary_wen   [1:0];
  logic [6:0]            tary_addr  [1:0];
  logic [`dTARY_W-1:0]   tary_wdata [1:0];
  logic [`dTARY_W-1:0]   tary_rdata [1:0];

  // data array signal:
  logic                  dary_ren   [1:0];
  logic                  dary_wen   [1:0];
  logic [6:0]            dary_addr  [1:0];
  logic [15:0]           dary_wstrb [1:0];
  logic [127:0]          dary_wdata [1:0];
  logic [127:0]          dary_rdata [1:0];

  for (genvar i=0; i<2 ; i=i+1) begin
    dCache_tag_ary #(
      .DATA_WIDTH (`dTARY_W)
    ) u_tag_ary(
      .i_clk   (i_clk         ),
      .i_rst_n (i_rst_n       ),
      .i_wen   (tary_wen  [i] ),
      .i_addr  (tary_addr [i] ),
      .i_din   (tary_wdata[i] ),
      .o_dout  (tary_rdata[i] )
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

  wire [`TAG_BIT] tag    = dCacheIf_S.addr[`ADR_WIDTH-1:11];
  wire [6:0]      index  = dCacheIf_S.addr[ 10:4];
  wire [3:0]      offset = dCacheIf_S.addr[  3:0];

  // 2. state machine: /////////////////////////////////////////////////////////////////////////////////////////////////////

  // signals used for dch_state_n logic:
  // signals for hit:
  wire [1:0]      hit;
  // signals for miss, replace victim block:
  wire            victimblk_wayid, victimblk_dirty, victimblk_valid;
  wire [`TAG_BIT] victimblk_tag;
  // signals for fence.i:
  wire            clean_hit_dirtyline;
  wire [7:0]      clean_cnt ;

  enum logic[2:0] {IDLE, WBUS, RBUS, HIT, CLEAN_CUNT, CLEAN_WBUS} state;
  logic [2:0] dch_state, dch_state_n;

  stl_reg #(
    .WIDTH      (3          ),
    .RESET_VAL  (IDLE       )
  ) reg_status (
  	.i_clk      (i_clk      ),
    .i_rst_n    (i_rst_n    ),
    .i_wen      (1'b1       ),
    .i_din      (dch_state_n),
    .o_dout     (dch_state  )
  );

  always @(*) begin
    case (dch_state)
      IDLE:       if(dCacheIf_S.valid)begin
                    if(i_clean) begin
                      dch_state_n = CLEAN_CUNT;
                    end else if(|hit) begin
                      dch_state_n = HIT;
                    end else if (victimblk_valid & victimblk_dirty) begin
                      dch_state_n = WBUS;
                    end else begin
                      dch_state_n = RBUS;
                    end
                  end else begin
                    dch_state_n = IDLE;
                  end
      WBUS:       if(dMemIf_M.ready)
                    dch_state_n = RBUS;
                  else
                    dch_state_n = WBUS;
      RBUS:       if(dMemIf_M.ready)
                    dch_state_n = IDLE;
                  else
                    dch_state_n = RBUS;
      HIT:        dch_state_n = IDLE;
      CLEAN_CUNT: if(clean_hit_dirtyline)
                    dch_state_n = CLEAN_WBUS;
                  else if(clean_cnt == 8'hff)
                    dch_state_n = IDLE;
                  else
                    dch_state_n = CLEAN_CUNT;
      CLEAN_WBUS: if(dMemIf_M.ready)begin
                    if(clean_cnt == 8'hff)
                      dch_state_n = IDLE;
                    else
                      dch_state_n = CLEAN_CUNT;
                  end else begin
                    dch_state_n = CLEAN_WBUS;
                  end
      default:    dch_state_n = IDLE;
    endcase
  end

  // 3. hit, read/write data array, update recent/dirty, update dCacheIf_S signal: ///////////////////////////////////////////

  for (genvar i=0; i<2 ; i=i+1) begin
    assign hit[i] = (tary_rdata[i][`TAG_BIT] == tag) & tary_rdata[i][`VLD_BIT];
  end

  logic                 tary_hit_wen   [1:0];
  logic [`dTARY_W-1:0]  tary_hit_wdata [1:0];
  logic                 dary_hit_ren   [1:0];
  logic                 dary_hit_wen   [1:0];
  logic [15:0]          dary_hit_wstrb [1:0];
  logic [127:0]         dary_hit_wdata [1:0];

  // 3.1 update recent://////////////////////////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<128; i=i+1 ) begin
    assign recent_wen[i] = (dch_state == HIT) & (index == i);
  end
  assign recent_wdata = hit[1];

  // 3.2 read data array: ///////////////////////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign dary_hit_ren  [i] = (dch_state_n == HIT) & hit[i] & (dCacheIf_S.reqtyp == `REQ_READ);
  end

  wire [127:0] hit_cacheline = hit[1] ? dary_rdata[1] : (hit[0] ? dary_rdata[0] : 128'b0);

  // 3.3 write data array, update tag array dirty bit: ///////////////////////////////////////////////////////////////////////
  wire [7:0] wstrb;
  stl_mux_default #(4, 2, 8) mux_size (wstrb, dCacheIf_S.size, 8'b0, {
    2'b00 , 8'b0000_0001, // 1 byte.
    2'b01 , 8'b0000_0011, // 2 byte.
    2'b10 , 8'b0000_1111, // 4 byte.
    2'b11 , 8'b1111_1111  // 8 byte.
  });

  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_hit_wen   [i] = (dCacheIf_S.reqtyp == `REQ_WRITE) & (dch_state == HIT) & hit[i];
    assign tary_hit_wdata [i] = {1'b1,tary_rdata[i][`dTARY_W-2:0]};       // dirty bit <= 1;
    assign dary_hit_wen   [i] = (dCacheIf_S.reqtyp == `REQ_WRITE) & (dch_state == HIT) & hit[i];
    assign dary_hit_wstrb [i] = {8'b0, wstrb} << offset;                    // bytes.
    assign dary_hit_wdata [i] = {64'b0, dCacheIf_S.wdata} << {offset,3'b0}; // bits. {offset,3'b0} means (offset*8)
  end

  // 3.4 update dCacheIf_S signal: ///////////////////////////////////////////////////////////////////////////////////////////
  logic                     dCacheIf_miss_ready;
  logic [`CPU_WIDTH-1:0]    dCacheIf_miss_rdata;
  logic [2*`CPU_WIDTH-1:0]  hit_cacheline_shift;

  assign dCacheIf_miss_ready = (dch_state == HIT);
  assign hit_cacheline_shift = hit_cacheline >> {offset,3'b0};
  assign dCacheIf_miss_rdata = hit_cacheline_shift[`CPU_WIDTH-1:0];

  // 4. miss, write dirty cacheline to bus, read new cacheline from bus : ///////////////////////////////////////////////////
  assign victimblk_wayid = ~recent[index];
  assign victimblk_dirty = tary_rdata[victimblk_wayid][`DRT_BIT];
  assign victimblk_valid = tary_rdata[victimblk_wayid][`VLD_BIT];
  assign victimblk_tag   = tary_rdata[victimblk_wayid][`TAG_BIT];

  logic                 tary_miss_wen   [1:0];
  logic [`dTARY_W-1:0]  tary_miss_wdata [1:0];
  logic                 dary_miss_ren   [1:0];
  logic                 dary_miss_wen   [1:0];
  logic [15:0]          dary_miss_wstrb [1:0];
  logic [127:0]         dary_miss_wdata [1:0];

  // 4.1 read dirty victim block, write bus: ///////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    assign dary_miss_ren  [i] = (dch_state_n == WBUS) & (i == victimblk_wayid);
  end

  // 4.2 read bus, write to victim block: //////////////////////////////////////////////////////////////////////////////////
  for (genvar i=0; i<2 ; i=i+1) begin
    // assign tary_miss_wen    [i] = dMemIf_miss_valid & dMemIf_M.ready & (i == victimblk_wayid);
    // assign tary_miss_wdata  [i] = (dch_state == WBUS) ? {1'b0, victimblk_valid, victimblk_tag}: {1'b0, 1'b1, tag};  //{dirty,valid,tag};
    assign tary_miss_wen    [i] = (dch_state == RBUS) & dMemIf_M.ready & (i == victimblk_wayid);
    assign tary_miss_wdata  [i] = {1'b0, 1'b1, tag};  //{dirty,valid,tag};
    assign dary_miss_wen    [i] = (dch_state == RBUS) & dMemIf_M.ready & (i == victimblk_wayid);
    assign dary_miss_wstrb  [i] = 16'hffff;
    assign dary_miss_wdata  [i] = dMemIf_M.rdata;
  end

  // 4.3 update dMemIf_M signal: //////////////////////////////////////////////////////////////////////////////////////////
  logic                   dMemIf_miss_valid  ;
  logic                   dMemIf_miss_reqtyp ;
  logic [`ADR_WIDTH-1:0]  dMemIf_miss_addr   ;
  logic [127:0]           dMemIf_miss_wdata  ;

  assign dMemIf_miss_valid  =  (dch_state == WBUS) | (dch_state == RBUS) ;
  assign dMemIf_miss_reqtyp =  (dch_state == WBUS) ? `REQ_WRITE : `REQ_READ;
  assign dMemIf_miss_addr   =  (dch_state == WBUS) ? {victimblk_tag, index, 4'b0} : {tag, index, 4'b0};
  assign dMemIf_miss_wdata  =  (dch_state == WBUS) ? dary_rdata[victimblk_wayid] : 128'b0;

  // 5. clean dCache signals.///////////////////////////////////////////////////////////////////////////////////////////////

  // 5.1 count cacheline times. ////////////////////////////////////////////////////////////////////////////////////////////
  
  // clean_cnt[7] means way, clean_cnt[6:0] means index of set.
  stl_reg #(
    .WIDTH      (8              ),
    .RESET_VAL  (8'hff          ) // full.
  ) reg_count (
    .i_clk      (i_clk          ),
    .i_rst_n    (i_rst_n        ),
    .i_wen      (dch_state_n == CLEAN_CUNT),
    .i_din      (clean_cnt+1'b1 ),
    .o_dout     (clean_cnt      )
  );

  // 5.2 read dirty cacheline, write bus: //////////////////////////////////////////////////////////////////////////////////
  logic                 cleanblk_wayid, cleanblk_dirty, cleanblk_valid;
  logic [6:0]           cleanblk_index;
  logic [`TAG_W-1:0]    cleanblk_tag;

  logic                 tary_clean_wen   [1:0];
  logic [`dTARY_W-1:0]  tary_clean_wdata [1:0];
  logic                 dary_clean_ren   [1:0];

  assign cleanblk_index = clean_cnt[6:0];
  assign cleanblk_wayid = clean_cnt[7];
  assign cleanblk_dirty = tary_rdata[cleanblk_wayid][`DRT_BIT];
  assign cleanblk_valid = tary_rdata[cleanblk_wayid][`VLD_BIT];
  assign cleanblk_tag   = tary_rdata[cleanblk_wayid][`TAG_BIT];

  assign clean_hit_dirtyline = cleanblk_valid & cleanblk_dirty;

  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_clean_wen   [i] = (i == clean_cnt[7]) & (dch_state == CLEAN_WBUS) & dMemIf_M.ready;
    assign tary_clean_wdata [i] = {1'b0, cleanblk_valid, cleanblk_tag};  //{dirty,valid,tag};
    assign dary_clean_ren   [i] = (i == clean_cnt[7]) & (dch_state_n == CLEAN_WBUS);
  end

  // 5.4 update dMemIf_M signal: //////////////////////////////////////////////////////////////////////////////////////////
  logic                   dMemIf_clean_valid  ;
  logic                   dMemIf_clean_reqtyp ;
  logic [`ADR_WIDTH-1:0]  dMemIf_clean_addr   ;
  logic [127:0]           dMemIf_clean_wdata  ;

  assign dMemIf_clean_valid  = (dch_state == CLEAN_WBUS);
  assign dMemIf_clean_reqtyp = `REQ_WRITE;
  assign dMemIf_clean_addr   = {cleanblk_tag, cleanblk_index, 4'b0};
  assign dMemIf_clean_wdata  = dary_rdata[cleanblk_wayid];

  // 5.5 update dCacheIf_S signal: /////////////////////////////////////////////////////////////////////////////////////////

  logic                   dCacheIf_clean_ready  ;
  logic [`CPU_WIDTH-1:0]  dCacheIf_clean_rdata  ;

  assign dCacheIf_clean_ready = (dch_state == CLEAN_CUNT | dch_state == CLEAN_WBUS) & (dch_state_n == IDLE);
  assign dCacheIf_clean_rdata = `CPU_WIDTH'b0;

  // 6. all signals combination ://////////////////////////////////////////////////////////////////////////////////////////

  for (genvar i=0; i<2 ; i=i+1) begin
    assign tary_wen    [i] = tary_miss_wen[i] | tary_hit_wen   [i] | tary_clean_wen[i];
    assign tary_addr   [i]=  i_clean ? cleanblk_index : index;
    assign tary_wdata  [i] = tary_miss_wen[i] ? tary_miss_wdata[i] : (tary_hit_wen [i] ? tary_hit_wdata[i] : tary_clean_wdata [i]);
    assign dary_ren    [i] = dary_miss_ren[i] | dary_hit_ren   [i] | dary_clean_ren[i];
    assign dary_wen    [i] = dary_miss_wen[i] | dary_hit_wen   [i] ;
    assign dary_addr   [i]=  i_clean ? cleanblk_index : index;
    assign dary_wstrb  [i] = dary_miss_wen[i] ? dary_miss_wstrb[i] : dary_hit_wstrb[i];
    assign dary_wdata  [i] = dary_miss_wen[i] ? dary_miss_wdata[i] : dary_hit_wdata[i];
  end

  // dMemIf_M signal: input: ready, rdata; output: valid, reqtyp, addr, wdata, size;
  assign dMemIf_M.valid  =  dMemIf_clean_valid | dMemIf_miss_valid;
  assign dMemIf_M.reqtyp =  dMemIf_clean_valid ? dMemIf_clean_reqtyp : dMemIf_miss_reqtyp ;
  assign dMemIf_M.addr   =  dMemIf_clean_valid ? dMemIf_clean_addr   : dMemIf_miss_addr   ;
  assign dMemIf_M.wdata  =  dMemIf_clean_valid ? dMemIf_clean_wdata  : dMemIf_miss_wdata  ;
  assign dMemIf_M.size   =  2'b11;

  // dCacheIf_S signal: input:  valid, addr, reqtyp, wdata, size; output: ready, rdata;
  assign dCacheIf_S.ready = dCacheIf_clean_ready | dCacheIf_miss_ready ;
  assign dCacheIf_S.rdata = dCacheIf_clean_ready ? dCacheIf_clean_rdata : dCacheIf_miss_rdata ;

endmodule
