module iCache_tag_ary#(
  DATA_WIDTH = 64
)(
  input                         i_clk     ,
  input                         i_rst_n   ,
  input                         i_invalid ,
  input                         i_wen     ,
  input       [  6:0]           i_addr    , // 7 bit, 128 depth.
  input       [DATA_WIDTH-1:0]  i_din     ,
  output      [DATA_WIDTH-1:0]  o_dout
);

  logic [DATA_WIDTH-1:0] tag_array [127:0];
  logic [DATA_WIDTH-1:0] wdata     [127:0];
  logic [127:0] wen;

  for (genvar i=0; i<128; i=i+1) begin
    assign wen  [i]           = i_invalid | (i_wen & (i_addr == i));
    assign wdata[i][`VLD_BIT] = i_invalid ? 1'b0                   : i_din[`VLD_BIT];
    assign wdata[i][`TAG_BIT] = i_invalid ? tag_array[i][`TAG_BIT] : i_din[`TAG_BIT];

    stl_reg #(
      .WIDTH      (DATA_WIDTH   ),
      .RESET_VAL  (0            )
    ) u_reg (
      .i_clk      (i_clk        ),
      .i_rst_n    (i_rst_n      ),
      .i_wen      (wen[i]       ),
      .i_din      (wdata[i]     ),
      .o_dout     (tag_array[i] )
    );
  end

  assign o_dout = tag_array[i_addr];

endmodule
