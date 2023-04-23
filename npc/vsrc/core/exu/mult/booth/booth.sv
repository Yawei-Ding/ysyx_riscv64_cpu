module booth #(
  parameter INXY_W = 66 ,
  parameter PSUM_W = INXY_W*2,
  parameter PSUM_N = INXY_W/2
)(
  input  [INXY_W-1:0] x,
  input  [INXY_W-1:0] y,
  output [PSUM_W-1:0] psum [PSUM_N-1:0] // partial sum with shift and sign extension
);

  logic [INXY_W:0] psum_raw [PSUM_N-1:0];
  logic            clow_raw [PSUM_N-1:0];

  booth_1bit #(.WIDTH (INXY_W)) B_0(.x (x),.s ({y[1:0], 1'b0}),.psum (psum_raw[0]), .clow(clow_raw[0]));
  assign psum[0] = {{(INXY_W-1){psum_raw[0][INXY_W]}}, psum_raw[0]};  // 65bit sign extension + 67bit psum_raw.
  for(genvar i=1; i<PSUM_N; i=i+1) begin: gen_shift_partial_sum
    booth_1bit #(.WIDTH (INXY_W)) B_(.x (x),.s (y[2*i+1 : 2*i-1]),.psum (psum_raw[i]), .clow(clow_raw[i]));
    assign psum[i] = {{(INXY_W-1-2*i){psum_raw[i][INXY_W]}}, psum_raw[i], 1'b0, clow_raw[i-1], {(2*i-2){1'b0}}};
  end

endmodule
