module ifu (
  // 1. signal to pipe shake hands:
  input                           i_clk       ,
  input                           i_rst_n     ,
  output                          o_post_valid,   //  to  post-stage
  input                           i_post_ready,   // from post-stage

  // 2. input comb signal from pre stage:
  input         [`CPU_WIDTH-1:0]  i_next_pc   ,
  
  // 3. output comb signal to post stage:
  output logic  [`CPU_WIDTH-1:0]  o_ifu_pc    ,
  output logic  [`INS_WIDTH-1:0]  o_ifu_ins
);

  // 1. shake hands to reg pre stage signals://///////////////////////////////////////////////////////////////
  // remind: there is no shake hands signals from pre stage for ifu, so just use post stage signals to shank hands.
  wire pipewen;
  assign o_post_valid = 1;
  assign pipewen = o_post_valid & i_post_ready;

  logic  [`CPU_WIDTH-1:0]  next_pc_r;

  stl_reg #(
    .WIDTH     (`CPU_WIDTH          ),
    .RESET_VAL (`CPU_WIDTH'h80000000)
  ) prereg (
    .i_clk   (i_clk       ),
    .i_rst_n (i_rst_n     ),
    .i_wen   (pipewen     ),
    .i_din   (i_next_pc   ),
    .o_dout  (next_pc_r   )
  );

  // 2. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////

  assign o_ifu_pc = next_pc_r;

  ifu_logic u_ifu_logic(
    .i_rst_n (i_rst_n   ),
    .i_pc    (next_pc_r ),
    .o_ins   (o_ifu_ins )
  );

endmodule
