module csa_nbit#(
  parameter N = 64
)(
  input  [N-1:0] i_a, 
  input  [N-1:0] i_b, 
  input  [N-1:0] i_c, 
  output [N-1:0] o_s, 
  output [N-1:0] o_c
);

  wire [N-1:0] p;
  wire [N-1:0] g;

  genvar i;
  generate
    for(i=0; i<N; i=i+1)begin:csa
      assign g[i] = i_a[i] & i_b[i];
      assign p[i] = i_a[i] ^ i_b[i];
      assign o_s[i] = p[i] ^ i_c[i];
      assign o_c[i] = i_c[i] & p[i] | g[i] ;
    end
  endgenerate

endmodule
