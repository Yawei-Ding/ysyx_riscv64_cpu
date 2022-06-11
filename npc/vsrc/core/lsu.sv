module lsu (
  input                               i_clk   ,
  input                               i_rst_n , 
  input         [2:0]                 i_lsfunc3,
  input                               i_lden  ,
  input                               i_sten  ,
  input         [`CPU_WIDTH-1:0]      i_addr  ,   // mem i_addr. from exu result.
  input         [`CPU_WIDTH-1:0]      i_regst ,   // for st.
  output  logic [`CPU_WIDTH-1:0]      o_regld     // for ld.
);

  wire ren = i_lden;
  wire [`CPU_WIDTH-1:0] raddr = i_addr;
  wire [`CPU_WIDTH-1:0] rdata;
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

  logic [7:0] mask,wmask;
  logic [`CPU_WIDTH-1:0] waddr,wdata;
  always @(*) begin
    case (i_lsfunc3)
      `FUNC3_LB_SB:  mask = 8'b0000_0001 & {8{i_sten}};
      `FUNC3_LH_SH:  mask = 8'b0000_0011 & {8{i_sten}};
      `FUNC3_LW_SW:  mask = 8'b0000_1111 & {8{i_sten}};
      `FUNC3_LD_SD:  mask = 8'b1111_1111 & {8{i_sten}};
      default:       mask = 8'b0;
    endcase
  end

  // Due to comb logic delay, there must use an reg!!
  // Think about this situation: if waddr and wdata is not ready, but write it to mem immediately. it's wrong! 
  stdreg #(
    .WIDTH     (2*`CPU_WIDTH+8),
    .RESET_VAL (0 )
  ) u_stdreg(
    .i_clk   (i_clk                 ),
    .i_rst_n (i_rst_n               ),
    .i_wen   (1                     ),
    .i_din   ({i_addr,i_regst,mask} ),
    .o_dout  ({waddr, wdata, wmask} )
  );
    
  //for sim:  ////////////////////////////////////////////////////////////////////////////////////////////
  import "DPI-C" function void rtl_pmem_read (input longint raddr, output longint rdata, input bit ren);
  import "DPI-C" function void rtl_pmem_write(input longint waddr, input longint wdata, input byte wmask);
  always @(*) begin
    rtl_pmem_read (raddr, rdata, ren);
    rtl_pmem_write(waddr, wdata, wmask);
  end

endmodule
