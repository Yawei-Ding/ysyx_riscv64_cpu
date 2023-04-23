module mult #(
  parameter W = 64          // width should not be changed, only support 64 now.
)(
  input             i_mulw  ,
  input             i_x_sign,
  input             i_y_sign,
  input 	[W-1:0]   i_x     ,
  input 	[W-1:0]   i_y     ,
  output 	[W-1:0]   o_hi_res,
  output 	[W-1:0]   o_lw_res
);

  localparam EXTEN_W = W + 2 ; // 2 for signed extension, 66 totally.
  localparam PSUM_W = EXTEN_W*2;
  localparam PSUM_N = EXTEN_W/2;

  logic	[EXTEN_W-1:0] x, y;

  assign x = i_mulw ? {{(2+W/2){i_x[W/2-1]}}, i_x[W/2-1:0]} : {i_x_sign ? {2{i_x[W-1]}} : 2'b0, i_x[W-1:0]};
  assign y = i_mulw ? {{(2+W/2){i_y[W/2-1]}}, i_y[W/2-1:0]} : {i_y_sign ? {2{i_y[W-1]}} : 2'b0, i_y[W-1:0]};

  // 1. generate partial product://///////////////////////////////////////////////////////////
  logic  [PSUM_W-1:0] psum [PSUM_N-1:0];

  booth #(
    .INXY_W(EXTEN_W),
    .PSUM_W(PSUM_W),
    .PSUM_N(PSUM_N)
  ) u_booth (
    .x   (x   ),
    .y   (y   ),
    .psum(psum)
  );

  // 2. use wallace tree to generate result://////////////////////////////////////////////////
  wire [PSUM_W-1:0] tree_out [1:0];
  wallace_tree_33 #(PSUM_W) wallace_tree (.in(psum),.out(tree_out));

  // 3. full connect adder://///////////////////////////////////////////////////////////////////
  logic [PSUM_W-1:0] res;
  logic carry;

  rca_nbit #(
    .N (PSUM_W)
  ) u_rca_nbit(
    .i_a (tree_out[1]),
    .i_b (tree_out[0]),
    .i_c (1'b0       ),
    .o_s (res        ),
    .o_c (carry      ));

  assign {o_hi_res, o_lw_res} = res[2*W-1:0];

endmodule
