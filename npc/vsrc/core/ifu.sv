`include "config.sv"
module ifu (
  input                          i_rst_n,
  input        [`CPU_WIDTH-1:0]  i_pc   ,
  output logic [`INS_WIDTH-1:0]  o_ins   
);

  logic [`CPU_WIDTH-1:0] ins;
  
  import "DPI-C" function void rtl_pmem_read (input longint raddr, output longint rdata, input bit ren);

  always @(*) begin
    rtl_pmem_read (i_pc, ins, i_rst_n);
  end

  assign o_ins = {ins & `CPU_WIDTH'h00000000FFFFFFFF}[`INS_WIDTH-1:0];

endmodule
