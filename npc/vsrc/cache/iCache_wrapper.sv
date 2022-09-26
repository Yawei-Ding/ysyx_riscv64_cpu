`include "defines.sv"
module iCache_wrapper (
  input                       i_clk     ,
  input                       i_rst_n   ,
  input                       i_invalid ,
  uni_if.Slave                iCacheIf_S,  //  32 bit width
  uni_if.Master               iMemIf_M     // 128 bit width
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
  // only cachable interface can read iCache, otherwise iCacheIf_S connect iMemIf_M directly.

  wire cachable = iCacheIf_S.addr[31];

  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(`INS_WIDTH)) iCachableCacheIf();
  uni_if #(.ADDR_W(`ADR_WIDTH), .DATA_W(128)) iCachableMemIf();

  assign iCachableCacheIf.valid    = iCacheIf_S.valid & cachable;
  assign iCachableCacheIf.reqtyp   = iCacheIf_S.reqtyp   ;
  assign iCachableCacheIf.addr     = iCacheIf_S.addr     ;
  assign iCachableCacheIf.wdata    = iCacheIf_S.wdata    ;
  assign iCachableCacheIf.size     = iCacheIf_S.size     ;

  assign iCachableMemIf.ready      = iMemIf_M.ready & cachable;
  assign iCachableMemIf.rdata      = iMemIf_M.rdata;

  iCache u_iCache(
    .i_clk      (i_clk            ),
    .i_rst_n    (i_rst_n          ),
    .i_invalid  (i_invalid        ),
    .iCacheIf_S (iCachableCacheIf ),
    .iMemIf_M   (iCachableMemIf   )
  );

  assign iCacheIf_S.ready  = cachable ? iCachableCacheIf.ready  : iMemIf_M.ready    ;
  assign iCacheIf_S.rdata  = cachable ? iCachableCacheIf.rdata  : iMemIf_M.rdata[`INS_WIDTH-1:0];

  assign iMemIf_M.valid    = cachable ? iCachableMemIf.valid    : iCacheIf_S.valid  ;
  assign iMemIf_M.reqtyp   = cachable ? iCachableMemIf.reqtyp   : iCacheIf_S.reqtyp ;
  assign iMemIf_M.addr     = cachable ? iCachableMemIf.addr     : iCacheIf_S.addr   ;
  assign iMemIf_M.wdata    = cachable ? iCachableMemIf.wdata    : {{(128-`INS_WIDTH){1'b0}},iCacheIf_S.wdata};
  assign iMemIf_M.size     = cachable ? iCachableMemIf.size     : iCacheIf_S.size   ;

  assign iMemIf_M.cachable = cachable ; // use for uni2axi size/len.

endmodule
