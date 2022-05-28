`include "vsrc/lib/define.sv"
module wbu (
  input         [`CPU_WIDTH-1:0]  exu_res,
  input         [`CPU_WIDTH-1:0]  lsu_res,
  input                           load_en,
  output logic  [`CPU_WIDTH-1:0]  rd     
);
  
  assign rd = load_en ? lsu_res : exu_res;
    
endmodule