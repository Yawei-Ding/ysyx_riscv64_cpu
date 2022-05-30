module lsu (
  input                               clk   ,
  input         [`LSU_OPT_WIDTH-1:0]  opt   ,   // lsu opt.
  input         [`CPU_WIDTH-1:0]      addr  ,   // mem addr. from exu result.
  input         [`CPU_WIDTH-1:0]      regst ,   // for st.
  output  logic [`CPU_WIDTH-1:0]      regld     // for ld.
);

  wire ren = ~opt[0];
  wire [`CPU_WIDTH-1:0] raddr = addr;
  wire [`CPU_WIDTH-1:0] rdata;
  always @(*) begin
    case (opt)
      `LSU_LB:  regld = {{56{rdata[ 7]}}, rdata[ 7:0]};
      `LSU_LH:  regld = {{48{rdata[15]}}, rdata[15:0]};
      `LSU_LW:  regld = {{32{rdata[31]}}, rdata[31:0]};
      `LSU_LD:  regld = rdata;
      `LSU_LBU: regld = {56'b0, rdata[ 7:0]};
      `LSU_LHU: regld = {48'b0, rdata[15:0]};
      `LSU_LWU: regld = {32'b0, rdata[31:0]};
      default:  regld = `CPU_WIDTH'b0;
    endcase
  end

  logic [7:0] mask,wmask;
  logic [`CPU_WIDTH-1:0] waddr,wdata;
  always @(*) begin
    case (opt)
      `LSU_SB:  mask = 8'b0000_0001;
      `LSU_SH:  mask = 8'b0000_0011;
      `LSU_SW:  mask = 8'b0000_1111;
      `LSU_SD:  mask = 8'b1111_1111;
      default:  mask = 8'b0;
    endcase
  end

  // Due to comb logic delay, there must use an reg!!
  // Think about this situation: if waddr and wdata is not ready, and write it to mem immediately. it's wrong! 
  always @(posedge clk) begin
    waddr <= addr;
    wdata <= regst;
    wmask <= mask;
  end

  import "DPI-C" function void rtl_pmem_read (input longint raddr, output longint rdata, input bit ren);
  import "DPI-C" function void rtl_pmem_write(input longint waddr, input longint wdata, input byte wmask);
  always @(*) begin
    rtl_pmem_read (raddr, rdata, ren);
    rtl_pmem_write(waddr, wdata, wmask);
  end

endmodule
