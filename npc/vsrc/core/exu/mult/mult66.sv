module mult66 #(
  parameter WDITH = 66
)(
  input 	[WDITH-1:0]   x,
  input 	[WDITH-1:0]   y,
  output 	[2*WDITH-1:0] res
);

  localparam PNUM = WDITH/2;

  // 1. generate partial product://///////////////////////////////////////////////////////////
  wire  [WDITH:0] p[PNUM-1:0];
  wire  c [PNUM-1:0];

  booth #(.WDITH (WDITH)) B_0(.x (x),.s ({y[1:0], 1'b0}),.p (p[0]),.c (c[0]));
  for(genvar i=1; i<PNUM; i=i+1)begin:Booths
    booth #(.WDITH (WDITH)) B_(.x (x),.s (y[2*i+1 : 2*i-1]),.p (p[i]),.c (c[i]));
  end

  // 2. use wallace tree to generate result://////////////////////////////////////////////////
  wire [2*WDITH-1:0] tree_in [PNUM-1:0];	// with modified sign extension
  wire [2*WDITH-1:0] tree_out [1:0];
  assign tree_in[ 0] = {{(WDITH-1){c[0]}} , p[0]	};
  for(genvar i=1; i<PNUM; i=i+1)begin:gen_tree_in
    assign tree_in[i] = {{(WDITH-1-2*i){c[i]}}, p[i], 1'b0, c[i-1], {(2*i-2){1'b0}}};
  end

  wallace_tree_33 #(2*WDITH) wallace_tree (.in(tree_in),.out(tree_out));

  // 3. full connect adder://///////////////////////////////////////////////////////////////////
  rca_nbit #(.N (2*WDITH)) u_rca_nbit(.i_a (tree_out[1]),.i_b (tree_out[0]), .i_c (0),.o_s (res));

endmodule
