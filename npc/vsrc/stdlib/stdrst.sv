module stdrst(
  input   i_clk        ,
  input   i_rst_n      , 
  output  o_rst_n_sync
);

  reg rst_n_r1,rst_n_r2;

  always @ (posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        rst_n_r1 <= 1'b0 ; 
        rst_n_r2 <= 1'b0 ;
    end 
    else begin
        rst_n_r1 <= 1'b1  ; 
        rst_n_r2 <= rst_n_r1; 
    end
  end

  assign o_rst_n_sync = rst_n_r2 ;

endmodule
