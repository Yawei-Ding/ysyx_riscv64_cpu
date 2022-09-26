`include "defines.sv"
module dCache_wrapper (
  input                       i_clk     ,
  input                       i_rst_n   ,
  input                       i_clean   ,
  uni_if.Slave                dCacheIf_S,  //  64 bit width
  uni_if.Master               dMemIf_M     // 128 bit width
);

/*    device                    address
      reserve             0x0000_0000~0x01ff_ffff
       CLINT              0x0200_0000~0x0200_ffff
      reserve             0x0201_0000~0x0fff_ffff
     UART16550            0x1000_0000~0x1000_0fff
    SPI controller        0x1000_1000~0x1000_1fff
        SPI	              0x1000_1000~0x1000_1fff
        VGA	              0x1000_2000~0x1000_2fff
        PS2	              0x1000_3000~0x1000_3fff
      Ethernet	          0x1000_4000~0x1000_4fff
      Reserve	            0x1000_5000~0x2fff_ffff
  SPI-flash XIP mode      0x3000_0000~0x3fff_ffff
    ChipLink MMIO         0x4000_0000~0x7fff_ffff
       MEM	              0x8000_0000~0xfbff_ffff
      SDRAM	              0xfc00_0000~0xffff_ffff
*/

  // in this module, choose cachable memory, or uncachable device.
  // only cachable interface can read dCache, otherwise dCacheIf_S connect dMemIf_M directly.

  wire cachable = dCacheIf_S.addr[31] | i_clean;

  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(`CPU_WIDTH)) dCachableCacheIf();
  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(128)) dCachableMemIf();

  assign dCachableCacheIf.valid    = dCacheIf_S.valid & cachable;
  assign dCachableCacheIf.reqtyp   = dCacheIf_S.reqtyp   ;
  assign dCachableCacheIf.addr     = dCacheIf_S.addr     ;
  assign dCachableCacheIf.wdata    = dCacheIf_S.wdata    ;
  assign dCachableCacheIf.size     = dCacheIf_S.size     ;

  assign dCachableMemIf.ready      = dMemIf_M.ready & cachable;
  assign dCachableMemIf.rdata      = dMemIf_M.rdata;

  dCache u_dCache(
    .i_clk      (i_clk            ),
    .i_rst_n    (i_rst_n          ),
    .i_clean    (i_clean          ),
    .dCacheIf_S (dCachableCacheIf ),
    .dMemIf_M   (dCachableMemIf   )
  );

  assign dCacheIf_S.ready  = cachable ? dCachableCacheIf.ready  : dMemIf_M.ready    ;
  assign dCacheIf_S.rdata  = cachable ? dCachableCacheIf.rdata  : dMemIf_M.rdata[`CPU_WIDTH-1:0];

  assign dMemIf_M.valid    = cachable ? dCachableMemIf.valid    : dCacheIf_S.valid  ;
  assign dMemIf_M.reqtyp   = cachable ? dCachableMemIf.reqtyp   : dCacheIf_S.reqtyp ;
  assign dMemIf_M.addr     = cachable ? dCachableMemIf.addr     : dCacheIf_S.addr   ;
  assign dMemIf_M.wdata    = cachable ? dCachableMemIf.wdata    : {{(128-`CPU_WIDTH){1'b0}},dCacheIf_S.wdata};
  assign dMemIf_M.size     = cachable ? dCachableMemIf.size     : dCacheIf_S.size   ;

  assign dMemIf_M.cachable = cachable ; // use for uni2axi size/len.

endmodule
