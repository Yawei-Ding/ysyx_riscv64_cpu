module MuxKey #(
  NR_KEY = 2,
  KEY_LEN = 1,
  DATA_LEN = 1
) (
  output [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);

  MuxKeyInternal #(NR_KEY, KEY_LEN, DATA_LEN, 0) i0 (out, key, {DATA_LEN{1'b0}}, lut);

  // always @(*) begin      |         MuxKey #(2, 1, 1) i0 (y, s, {
  //  case (s)              |           1'b0, a,
  //    1'b0: y = a;        |  ====>    1'b1, b
  //    1'b1: y = b;        |         });
  //  endcase               |
  // end                    |

endmodule
