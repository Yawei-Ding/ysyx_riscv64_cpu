module rca_nbit#(
  parameter N = 64
)(
  input  [N-1:0] i_a, 
  input  [N-1:0] i_b, 
  input          i_c, 
  output [N-1:0] o_s, 
  output         o_c
);

  wire [N-1:0] p;
  wire [N-1:0] g;
  wire [N:0] c;
  assign c[0] = i_c;

  for(genvar i=0; i<N; i=i+1)begin:csa
    assign g[i]   = i_a[i] & i_b[i];
    assign p[i]   = i_a[i] ^ i_b[i];
    assign c[i+1] = c[i] & p[i] | g[i];
    assign o_s[i] = p[i] ^ c[i];
  end

  assign o_c = c[N];

endmodule
