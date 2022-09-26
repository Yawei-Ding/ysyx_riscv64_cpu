`include "defines.sv"
module ifu (
  input                           i_clk       ,
  input                           i_rst_n     ,

  // 1. cache interface to get data from cache/ddr:
  uni_if.Master                   iCacheIf_M  ,

  // 2. signal to pipe shake hands:
  input                           i_flush     ,
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

  wire post_sh = o_post_valid & i_post_ready;

  stl_reg #(
    .WIDTH     (`CPU_WIDTH          ),
    .RESET_VAL (`CPU_WIDTH'h80000000)
  ) prereg (
    .i_clk   (i_clk       ),
    .i_rst_n (i_rst_n     ),
    .i_wen   (post_sh | i_flush    ),
    .i_din   (i_next_pc   ),
    .o_dout  (next_pc_r   )
  );

  // 2. use interface to read ins ://////////////////////////////////////////

  // ⌈‾‾‾‾⌉              ⌈‾‾‾‾⌉ ready --> | --> o_post_valid
  // |REG|              |UNIF|          | 
  // ⌊____⌋    --> valid ⌊____⌋           | <-- i_post_ready

  logic wait_post_ready;
  logic [`INS_WIDTH-1:0] unif_rdata, unif_rdata_r;
  assign iCacheIf_M.valid  = !wait_post_ready ;
  assign iCacheIf_M.size   = 2'b10        ; // 32 bit.
  assign iCacheIf_M.reqtyp = `REQ_READ    ;
  assign iCacheIf_M.wdata  = `INS_WIDTH'b0; // no use.
  assign iCacheIf_M.addr   = next_pc_r[`ADR_WIDTH-1:0];
  assign unif_rdata = iCacheIf_M.rdata[`INS_WIDTH-1:0];

  // 3. use one register to save data/valid for post stage :///////////////////

  wire UniIf_Sh = iCacheIf_M.valid & iCacheIf_M.ready;

  stl_reg #(
    .WIDTH      (`INS_WIDTH   ),
    .RESET_VAL  (`INS_WIDTH'b0)
  ) unidatareg (
  	.i_clk      (i_clk        ),
    .i_rst_n    (i_rst_n      ),
    .i_wen      (UniIf_Sh     ),
    .i_din      (unif_rdata   ),
    .o_dout     (unif_rdata_r )
  );

  stl_reg #(
    .WIDTH      (1   ),                                       //  always_ff @(posedge i_clk or negedge i_rst_n) begin
    .RESET_VAL  (1'b0)                                        //    if(!i_rst_n)begin
  ) unireadyreg (                                             //      wait_post_ready <= 1'b0;
  	.i_clk      (i_clk                ),            // <==>   //    end else if(i_flush | post_sh)begin
    .i_rst_n    (i_rst_n              ),                      //      wait_post_ready <= 1'b0;
    .i_wen      (i_flush | post_sh | UniIf_Sh),               //    end else if(UniIf_Sh)begin
    .i_din      (!(i_flush | post_sh) ),                      //      wait_post_ready <= 1'b1;
    .o_dout     (wait_post_ready      )                       //    end
  );                                                          //  end

  // 4. use pre stage signals to generate comb logic for post stage://////////////////////////////////////////

  assign o_post_valid = UniIf_Sh | wait_post_ready; 
  assign o_ifu_pc     = next_pc_r;
  assign o_ifu_ins    = UniIf_Sh ? unif_rdata : unif_rdata_r;

endmodule
