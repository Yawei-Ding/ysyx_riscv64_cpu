module booth #(parameter WDITH=32) (
  input [WDITH-1:0] x,
  input [2:0] s,
  output wire [WDITH:0] p,
  output wire c
);

  wire y_add,y,y_sub; // y+1,y,y-1
  wire sel_negative,sel_double_negative,sel_positive,sel_double_positive;

  assign {y_add,y,y_sub} = s;

  assign sel_negative =  y_add & (y & ~y_sub | ~y & y_sub);
  assign sel_positive = ~y_add & (y & ~y_sub | ~y & y_sub);
  assign sel_double_negative =  y_add & ~y & ~y_sub;
  assign sel_double_positive = ~y_add &  y &  y_sub;

  assign p = sel_double_negative ? ~{x, 1'b0} : 
            (sel_double_positive ? {x, 1'b0} :
            (sel_negative ? ~{1'b0,x}:
            (sel_positive ?  {1'b0,x} : {(WDITH+1){1'b0}})));
  assign c = sel_double_negative | sel_negative ? 1'b1 : 1'b0;

endmodule
