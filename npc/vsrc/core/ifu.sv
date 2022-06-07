`include "config.sv"
module ifu (
  input        [`CPU_WIDTH-1:0]  i_pc   ,
  input                          i_rst_n,
  output logic [31:0]            o_ins   
);

  logic [`CPU_WIDTH-1:0] ins;
  
  import "DPI-C" function void rtl_pmem_read (input longint raddr, output longint rdata, input bit ren);
  import "DPI-C" function void diff_read_pc(input longint rtl_pc);
  always @(*) begin
    rtl_pmem_read (i_pc, ins, i_rst_n);
    diff_read_pc(i_pc);
  end

  assign o_ins = {ins & 64'h00000000FFFFFFFF}[31:0];

endmodule
