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

  assign ren = i_lden;
  assign raddr = i_addr;
  always @(*) begin
    case (i_lsfunc3)
      `FUNC3_LB_SB:  o_regld = {{56{rdata[ 7]}}, rdata[ 7:0]};
      `FUNC3_LH_SH:  o_regld = {{48{rdata[15]}}, rdata[15:0]};
      `FUNC3_LW_SW:  o_regld = {{32{rdata[31]}}, rdata[31:0]};
      `FUNC3_LD_SD:  o_regld = rdata;
      `FUNC3_LBU:    o_regld = {56'b0, rdata[ 7:0]};
      `FUNC3_LHU:    o_regld = {48'b0, rdata[15:0]};
      `FUNC3_LWU:    o_regld = {32'b0, rdata[31:0]};
      default:       o_regld = `CPU_WIDTH'b0;
    endcase
  end

  assign waddr = i_addr;
  assign wdata = i_regst;
  always @(*) begin
    case (i_lsfunc3)
      `FUNC3_LB_SB:  wmask = 8'b0000_0001 & {8{i_sten}};
      `FUNC3_LH_SH:  wmask = 8'b0000_0011 & {8{i_sten}};
      `FUNC3_LW_SW:  wmask = 8'b0000_1111 & {8{i_sten}};
      `FUNC3_LD_SD:  wmask = 8'b1111_1111 & {8{i_sten}};
      default:       wmask = 8'b0;
    endcase
  end
    
  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
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
