`include "config.sv"
module wbu (
  input         [`CPU_WIDTH-1:0]  i_exu_res,
  input         [`CPU_WIDTH-1:0]  i_lsu_res,
  input                           i_ldflag,
  output logic  [`CPU_WIDTH-1:0]  o_rd     
);
  
  assign o_rd = i_ldflag ? i_lsu_res : i_exu_res;
    
endmodule
