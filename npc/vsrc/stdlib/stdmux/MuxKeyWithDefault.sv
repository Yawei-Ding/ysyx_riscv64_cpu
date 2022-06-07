module MuxKeyWithDefault #(NR_KEY = 2, KEY_LEN = 1, DATA_LEN = 1) (
  output [DATA_LEN-1:0] out,
  input [KEY_LEN-1:0] key,
  input [DATA_LEN-1:0] default_out,
  input [NR_KEY*(KEY_LEN + DATA_LEN)-1:0] lut
);

  MuxKeyInternal #(NR_KEY, KEY_LEN, DATA_LEN, 1) i0 (out, key, default_out, lut);

  // always @(*) begin          |         MuxKeyWithDefault #(4, 2, 1) i0 (y, s, 1'b0, {
  //  case (s)                  |           2'b00, a[0],
  //    2'b00: y = a[0];        |           2'b01, a[1],
  //    2'b01: y = a[1];        |  ===>     2'b10, a[2],
  //    2'b10: y = a[2];        |           2'b11, a[3]
  //    2'b11: y = a[3];        |         });
  //    default: y = 1'b0;      |
  //  endcase                   |
  // end                        |

endmodule
