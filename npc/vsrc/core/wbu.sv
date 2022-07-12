`include "config.sv"
module wbu (
  input                           i_pre_valid ,   // from pre-stage
  output                          o_pre_ready ,   //  to  pre-stage
  input                           i_rdwen     ,
  input         [`CPU_WIDTH-1:0]  i_exu_res   ,
  input         [`CPU_WIDTH-1:0]  i_lsu_res   ,
  input                           i_ldflag    ,
  output logic                    o_rdwen     ,      
  output logic  [`CPU_WIDTH-1:0]  o_rd     
);
  
  assign o_pre_ready = 1;
  assign o_rdwen = i_pre_valid & o_pre_ready & i_rdwen;
  assign o_rd = i_ldflag ? i_lsu_res : i_exu_res;
    
endmodule
