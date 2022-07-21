module ifu (
  input                           i_clk       ,
  input                           i_rst_n     ,
  
  // 1. axi interface to get data from mem:
  uni_if.Master                   UniIf_M     ,

  // 2. signal to pipe shake hands:
  output                          o_post_valid,   //  to  post-stage
  input                           i_post_ready,   // from post-stage

  // 3. input signal from pre stage:
  input         [`CPU_WIDTH-1:0]  i_next_pc   ,

  // 4. output signal to post stage:
  output logic  [`CPU_WIDTH-1:0]  o_ifu_pc    ,
  output logic  [`INS_WIDTH-1:0]  o_ifu_ins
);

  // 1. shake hands to reg pre stage signals://///////////////////////////////////////////////////////////////
  // remind: there is no shake hands signals from pre stage for ifu, so just use post stage signals to shank hands.

  logic  [`CPU_WIDTH-1:0]  next_pc_r;

  wire pcwen;
  assign pcwen = o_post_valid & i_post_ready;

  stl_reg #(
    .WIDTH     (`CPU_WIDTH          ),
    .RESET_VAL (`CPU_WIDTH'h80000000)
  ) prereg (
    .i_clk   (i_clk       ),
    .i_rst_n (i_rst_n     ),
    .i_wen   (pcwen       ),
    .i_din   (i_next_pc   ),
    .o_dout  (next_pc_r   )
  );

  // 2. use interface to read ins ://////////////////////////////////////////

  // ⌈‾‾‾‾⌉              ⌈‾‾‾‾⌉ ready --> | --> o_post_valid
  // |REG|              |UNIF|          | 
  // ⌊____⌋    --> valid ⌊____⌋           | <-- i_post_ready
  //          ⌊______________________________⌋

  assign UniIf_M.valid  = 1'b1         ; //i_post_ready ;
  assign UniIf_M.addr   = next_pc_r    ;
  assign UniIf_M.reqtyp = 1'b0         ;   // read.
  assign UniIf_M.wdata  = `CPU_WIDTH'b0;   // no use.
  assign UniIf_M.size   = 2'b10        ;   // word, 32 bit

  assign o_post_valid = UniIf_M.ready;
  assign o_ifu_pc     = next_pc_r;
  assign o_ifu_ins    = UniIf_M.rdata[`INS_WIDTH-1:0];

endmodule
