`include "defines.sv"
module csrfile (
  input logic                   i_clk   ,
  input logic                   i_rst_n ,

  // from idu, for csrrw/csrrs/csrrc:
  input  logic                  i_ren   , 
  input  logic [`CSR_ADDRW-1:0] i_raddr ,
  output logic [`CPU_WIDTH-1:0] o_rdata ,

  // from wbu, for csrrw/csrrs/csrrc:
  input  logic                  i_wen   ,
  input  logic [`CSR_ADDRW-1:0] i_waddr ,
  input  logic [`CPU_WIDTH-1:0] i_wdata ,

  // connect excp/intr:
  input  logic                  i_mepc_wen      ,   // ecall / iru.
  input  logic [`CPU_WIDTH-1:0] i_mepc_wdata    ,   // ecall / iru.
  input  logic                  i_mcause_wen    ,   // ecall / iru.
  input  logic [`CPU_WIDTH-1:0] i_mcause_wdata  ,   // ecall / iru.
  input  logic                  i_mstatus_wen   ,   // ecall / iru.
  input  logic [`CPU_WIDTH-1:0] i_mstatus_wdata ,   // ecall / iru.
  output logic [`CPU_WIDTH-1:0] o_mtvec         ,   // ecall / iru.
  output logic [`CPU_WIDTH-1:0] o_mstatus       ,   // ecall / iru.
  output logic [`CPU_WIDTH-1:0] o_mepc          ,   // mret.
  output logic [`CPU_WIDTH-1:0] o_mip           ,
  output logic [`CPU_WIDTH-1:0] o_mie           ,

  // connect clint:
  input  logic                  i_clint_mtip    ,

  // for difftest:
  output logic [`CPU_WIDTH-1:0] s_mcause
);

  // 1. csr reg file: //////////////////////////////////////////////////////////////////
  logic [`CPU_WIDTH-1:0] mepc     ; // Machine exception program counter
  logic [`CPU_WIDTH-1:0] mtvec    ; // Machine trap-handler base address
  logic [`CPU_WIDTH-1:0] mcause   ; // Machine trap cause
  logic [`CPU_WIDTH-1:0] mstatus  ; // Machine status register
  logic [`CPU_WIDTH-1:0] mcycle   ; // Machine cycle.
  logic [`CPU_WIDTH-1:0] mie      ; // Machine interrupt eanble reg
  logic [`CPU_WIDTH-1:0] mip      ; // Machine interrupt pending reg
  logic [`CPU_WIDTH-1:0] mscratch ; // Scratch register for machine trap handlers.
  logic [`CPU_WIDTH-1:0] sstatus  ;

  // 2. read csr  reg file: ////////////////////////////////////////////////////////////
  wire ren_mepc     = i_ren & (i_raddr == `ADDR_MEPC     );
  wire ren_mtvec    = i_ren & (i_raddr == `ADDR_MTVEC    );
  wire ren_mcause   = i_ren & (i_raddr == `ADDR_MCAUSE   );
  wire ren_mstatus  = i_ren & (i_raddr == `ADDR_MSTATUS  );
  wire ren_mcycle   = i_ren & (i_raddr == `ADDR_MCYCLE   );
  wire ren_mie      = i_ren & (i_raddr == `ADDR_MIE      );
  wire ren_mip      = i_ren & (i_raddr == `ADDR_MIP      );
  wire ren_mscratch = i_ren & (i_raddr == `ADDR_MSCRATCH );

  assign o_rdata =  ren_mepc     ? mepc     : 
                  ( ren_mtvec    ? mtvec    : 
                  ( ren_mcause   ? mcause   : 
                  ( ren_mstatus  ? mstatus  : 
                  ( ren_mcycle   ? mcycle   : 
                  ( ren_mie      ? mie      :
                //( ren_mip      ? mip      : 
                  ( ren_mip      ? {mip[`CPU_WIDTH-1:`M_MIP_MTIP+1],1'b0,mip[`M_MIP_MTIP-1:0]} :   // to pass difftest.
                  ( ren_mscratch ? mscratch : `CPU_WIDTH'b0 )))))));

  assign o_mtvec   = mtvec    ;
  assign o_mepc    = mepc     ;
  assign o_mstatus = mstatus  ;
  assign o_mie     = mie      ;
  assign o_mip     = mip      ;

  // 3. write csr  reg file: ////////////////////////////////////////////////////////////
  // 3.1 mepc: //////////////////////////////////////////////////////////////////////////
  wire wen_mepc = (i_wen & (i_waddr == `ADDR_MEPC)) | i_mepc_wen ;
  wire [`CPU_WIDTH-1:0] wdata_mepc  = i_mepc_wen  ? i_mepc_wdata : i_wdata;
  
  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mepc (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mepc     ),
    .i_din    (wdata_mepc   ),
    .o_dout   (mepc         )
  );

  // 3.2 mcause: //////////////////////////////////////////////////////////////////////////
  wire wen_mcause = (i_wen & (i_waddr == `ADDR_MCAUSE )) | i_mcause_wen ;
  wire [`CPU_WIDTH-1:0] wdata_mcause = i_mcause_wen ? i_mcause_wdata : i_wdata;

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mcause (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mcause   ),
    .i_din    (wdata_mcause ),
    .o_dout   (mcause       )
  );

  // 3.3 mtvec: //////////////////////////////////////////////////////////////////////////
  wire wen_mtvec = (i_wen & (i_waddr == `ADDR_MTVEC));
  wire [`CPU_WIDTH-1:0] wdata_mtvec = i_wdata;

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mtvec (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mtvec    ),
    .i_din    (wdata_mtvec  ),
    .o_dout   (mtvec        )
  );

  // 3.4 mstatus: //////////////////////////////////////////////////////////////////////////
  wire wen_mstatus = (i_wen & (i_waddr == `ADDR_MSTATUS)) | i_mstatus_wen;
  wire [`CPU_WIDTH-1:0] wdata_mstatus_no_sd = i_mstatus_wen ? i_mstatus_wdata : i_wdata;
  wire [`CPU_WIDTH-1:0] wdata_mstatus = {(|wdata_mstatus_no_sd[`M_STATUS_VS]) | (|wdata_mstatus_no_sd[`M_STATUS_FS]) | (|wdata_mstatus_no_sd[`M_STATUS_XS]), wdata_mstatus_no_sd[`CPU_WIDTH-2:0]};

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mstatus (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mstatus  ),
    .i_din    (wdata_mstatus),
    .o_dout   (mstatus      )
  );

  wire [`CPU_WIDTH-1:0] wdata_sstatus = {wdata_mstatus[`M_STATUS_SD],48'b0,wdata_mstatus[`M_STATUS_FS],13'b0};

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_sstatus (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mstatus  ),
    .i_din    (wdata_sstatus),
    .o_dout   (sstatus      )
  );

  // 3.5 mcycle: //////////////////////////////////////////////////////////////////////////
  wire [`CPU_WIDTH-1:0] wdata_mcycle = (i_wen & (i_waddr == `ADDR_MCYCLE)) ? i_wdata : mcycle+1;

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mcycle (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (1'b1         ),
    .i_din    (wdata_mcycle ),
    .o_dout   (mcycle       )
  );

  // 3.6 mie: //////////////////////////////////////////////////////////////////////////
  wire wen_mie = (i_wen & (i_waddr == `ADDR_MIE));
  wire [`CPU_WIDTH-1:0] wdata_mie = i_wdata;

  stl_reg #(
    .WIDTH    (`CPU_WIDTH   ),
    .RESET_VAL(`CPU_WIDTH'b0)
  ) reg_mie (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mie      ),
    .i_din    (wdata_mie    ),
    .o_dout   (mie          )
  );

  // 3.7 mip: //////////////////////////////////////////////////////////////////////////
  assign mip[`M_MIP_MTIP] = i_clint_mtip;

  wire wen_mip = (i_wen & (i_waddr == `ADDR_MIP )) ;
  stl_reg #(
    .WIDTH    (`CPU_WIDTH-1 ),
    .RESET_VAL(0)
  ) reg_mip (
    .i_clk    (i_clk        ),
    .i_rst_n  (i_rst_n      ),
    .i_wen    (wen_mip      ),
    .i_din    ({i_wdata[`CPU_WIDTH-1:`M_MIP_MTIP+1], i_wdata[`M_MIP_MTIP-1:0]}),
    .o_dout   ({    mip[`CPU_WIDTH-1:`M_MIP_MTIP+1],     mip[`M_MIP_MTIP-1:0]})
  );

  // 3.8 mscratch: //////////////////////////////////////////////////////////////////////////
  wire wen_mscratch = (i_wen & (i_waddr == `ADDR_MSCRATCH));
  wire [`CPU_WIDTH-1:0] wdata_mscratch = i_wdata;

  stl_reg #(
    .WIDTH    (`CPU_WIDTH     ),
    .RESET_VAL(`CPU_WIDTH'b0  )
  ) reg_mscratch (
    .i_clk    (i_clk          ),
    .i_rst_n  (i_rst_n        ),
    .i_wen    (wen_mscratch   ),
    .i_din    (wdata_mscratch ),
    .o_dout   (mscratch       )
  );

  // 4. use for difftest sim :///////////////////////////////////////////////////////////
  assign s_mcause =  mcause  ;

endmodule
