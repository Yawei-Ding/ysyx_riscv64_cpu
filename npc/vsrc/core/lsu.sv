module lsu (
  input                               i_clk   ,
  input         [2:0]                 i_lsfunc3,
  input                               i_lden  ,
  input                               i_sten  ,
  input         [`CPU_WIDTH-1:0]      i_addr  ,   // mem i_addr. from exu result.
  input         [`CPU_WIDTH-1:0]      i_regst ,   // for st.
  output  logic [`CPU_WIDTH-1:0]      o_regld     // for ld.
);

  logic ren;
  logic [7:0] wmask;
  logic [`CPU_WIDTH-1:0] raddr,rdata,waddr,wdata;

  // for read:  ////////////////////////////////////////////////////////////////////////////////////////////
  assign ren = i_lden;
  assign raddr = i_addr;

  MuxKeyWithDefault #(7, 3, `CPU_WIDTH) mux_rdata (o_regld, i_lsfunc3, `CPU_WIDTH'b0, {
    `FUNC3_LB_SB,   {{56{rdata[ 7]}}, rdata[ 7:0]},
    `FUNC3_LH_SH,   {{48{rdata[15]}}, rdata[15:0]},
    `FUNC3_LW_SW,   {{32{rdata[31]}}, rdata[31:0]},
    `FUNC3_LD_SD,   rdata,
    `FUNC3_LBU,     {56'b0, rdata[ 7:0]},
    `FUNC3_LHU,     {48'b0, rdata[15:0]},
    `FUNC3_LWU,     {32'b0, rdata[31:0]}
  });

  // for write:  ////////////////////////////////////////////////////////////////////////////////////////////
  assign waddr = i_addr;
  assign wdata = i_regst;

  MuxKeyWithDefault #(4, 3, 8) mux_wmask (wmask, i_lsfunc3, 8'b0, {
    `FUNC3_LB_SB, 8'b0000_0001 & {8{i_sten}},
    `FUNC3_LH_SH, 8'b0000_0011 & {8{i_sten}},
    `FUNC3_LW_SW, 8'b0000_1111 & {8{i_sten}},
    `FUNC3_LD_SD, 8'b1111_1111 & {8{i_sten}}
  });

  // for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
  import "DPI-C" function void rtl_pmem_read (input longint raddr, output longint rdata, input bit ren);
  import "DPI-C" function void rtl_pmem_write(input longint waddr, input longint wdata, input byte wmask);
  always @(*) begin
    rtl_pmem_read (raddr, rdata, ren);
  end

  // Due to comb logic delay, there must use an reg for write!!
  // Think about this situation: if waddr and wdata is not ready, but write it to mem immediately. it's wrong! 
  always @(posedge i_clk) begin
    rtl_pmem_write(waddr, wdata, wmask);
  end

endmodule
