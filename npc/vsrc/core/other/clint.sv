`include "defines.sv"
module clint (
  input logic                   i_clk         ,
  input logic                   i_rst_n       ,

  // from cpu lsu:
  input  logic                  i_clint_ren   ,
  input  logic [`ADR_WIDTH-1:0] i_clint_raddr ,
  output logic [`CPU_WIDTH-1:0] o_clint_rdata ,
  input  logic                  i_clint_wen   ,
  input  logic [`ADR_WIDTH-1:0] i_clint_waddr ,
  input  logic [`CPU_WIDTH-1:0] i_clint_wdata ,
  
  // to csr_file:
  output logic                  o_clint_mtip
);

  reg [63:0] mtime, mtimecmp; // for both 32bit/64bit arch.

  // read:
  wire ren_mtimecmp, ren_mtime;
  assign ren_mtimecmp = i_clint_ren & (i_clint_raddr == `MTIMECMP_ADDR);
  assign ren_mtime    = i_clint_ren & (i_clint_raddr == `MTIME_ADDR   );
  assign o_clint_rdata = ren_mtime ? mtime : (ren_mtimecmp ? mtimecmp : 64'b0);

  // write:
  wire lsu_wen_mtime, cnt_wen_mtime, wen_mtimecmp, wen_mtime;
  wire [`CPU_WIDTH-1:0] wdata_mtimecmp, wdata_mtime;

  assign wen_mtimecmp   = i_clint_wen & (i_clint_waddr == `MTIMECMP_ADDR);
  assign wdata_mtimecmp = i_clint_wdata;

  assign lsu_wen_mtime  = i_clint_wen & (i_clint_waddr == `MTIME_ADDR   );
  assign cnt_wen_mtime  = !o_clint_mtip;
  assign wen_mtime      = lsu_wen_mtime | cnt_wen_mtime;
  assign wdata_mtime    = lsu_wen_mtime ? i_clint_wdata : (mtime + 1);

  stl_reg #(
    .WIDTH     (64    ),
    .RESET_VAL (64'b0 )
  ) reg_mtime (
    .i_clk     (i_clk         ),
    .i_rst_n   (i_rst_n       ),
    .i_wen     (wen_mtime     ),
    .i_din     (wdata_mtime   ),
    .o_dout    (mtime         )
  );

  stl_reg #(
    .WIDTH     (64    ),
    .RESET_VAL (64'b0 )
  ) reg_mtimcmp (
    .i_clk     (i_clk         ),
    .i_rst_n   (i_rst_n       ),
    .i_wen     (wen_mtimecmp  ),
    .i_din     (wdata_mtimecmp),
    .o_dout    (mtimecmp      )
  );

  assign o_clint_mtip = (mtime >= mtimecmp);

endmodule
