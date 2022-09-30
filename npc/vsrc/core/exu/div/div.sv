module div#(
  parameter WIDTH = 64
)(
  input                     i_clk         ,
  input                     i_rst_n       ,
  input                     i_flush       ,
  input                     i_divw        ,
  input                     i_start       ,
  output                    o_busy        ,
  output logic              o_end_valid   ,
  input                     i_end_ready   ,
  input                     i_signed      ,
  input  logic [WIDTH-1:0]  i_dividend    ,
  input  logic [WIDTH-1:0]  i_divisor     ,
  output logic [WIDTH-1:0]  o_quotient    ,
  output logic [WIDTH-1:0]  o_remainder
);

  // 1. control signal:///////////////////////////////////////////////////////////////////////
  localparam CNT_W = $clog2(WIDTH);
  
  logic [CNT_W-1:0] cnt;

  wire cntneq0 = |cnt;
  
  assign o_busy = (cntneq0) | o_end_valid;

  always@(posedge i_clk or negedge i_rst_n)begin
    if(!i_rst_n)begin
      cnt <= {CNT_W{1'b0}};
    end else if(i_flush) begin
      cnt <= {CNT_W{1'b0}};
    end else if(i_start) begin
      cnt <= i_divw ? {1'b0,{(CNT_W-1){1'b1}}} : {CNT_W{1'b1}}; // 31, 63.
    end else if(cntneq0) begin // cnt != 0
      cnt <= cnt - 1;
    end
  end

  always@(posedge i_clk or negedge i_rst_n)begin
    if(!i_rst_n)begin
      o_end_valid <= 1'b0;
    end else if(i_flush)begin
      o_end_valid <= 1'b0;
    end else if(cnt == {{(CNT_W-1){1'b0}},1'b1}) begin
      o_end_valid <= 1'b1;
    end else if(i_end_ready) begin
      o_end_valid <= 1'b0;
    end
  end

  // 2. deal input signals://///////////////////////////////////////////////////////////////////
  wire [WIDTH-1:0] i_dividend_wrapper = i_divw ? {{(WIDTH/2){i_dividend[WIDTH/2-1]}}, i_dividend[WIDTH/2-1:0]} : i_dividend;
  wire [WIDTH-1:0] i_divisor_wrapper  = i_divw ? {{(WIDTH/2){i_divisor [WIDTH/2-1]}}, i_divisor [WIDTH/2-1:0]} : i_divisor ;

  wire dividend_positive = i_signed ? ~i_dividend_wrapper[WIDTH-1] : 1;
  wire divisor_positive  = i_signed ? ~i_divisor_wrapper [WIDTH-1] : 1;

  wire [WIDTH-1:0] i_dividend_abs = dividend_positive ? i_dividend_wrapper : ~i_dividend_wrapper + 1'b1;
  wire [WIDTH-1:0] i_divisor_abs  = divisor_positive  ? i_divisor_wrapper  : ~i_divisor_wrapper  + 1'b1;

  // 3. div:///////////////////////////////////////////////////////////////////////////////////
  logic [WIDTH-1  :0] divisor_r;
  logic [2*WIDTH-1:0] dividend , dividend_r , dividend_r_shift ;
  logic [WIDTH-1  :0] quotient , quotient_r ;

  always@(posedge i_clk or negedge i_rst_n)begin
    if(!i_rst_n)begin
      dividend_r  <= {2*WIDTH{1'b0}};
      divisor_r   <= {  WIDTH{1'b0}};
      quotient_r  <= {  WIDTH{1'b0}};
    end else if(i_flush) begin
      dividend_r  <= {2*WIDTH{1'b0}};
      divisor_r   <= {  WIDTH{1'b0}};
      quotient_r  <= {  WIDTH{1'b0}};
    end else if(i_start) begin
      dividend_r  <= {{WIDTH{1'b0}}, i_dividend_abs};
      divisor_r   <= i_divisor_abs;
      quotient_r  <= {WIDTH{1'b0}};
    end else if(cntneq0) begin
      dividend_r  <= dividend ;
      quotient_r  <= quotient ;
    end
  end

  logic [WIDTH-1:0] div_sub, mask;
  logic sub_positive, sub_negative;

  assign dividend_r_shift = {dividend_r >> cnt};
  assign {sub_negative,div_sub} = dividend_r_shift[WIDTH:0] - {1'b0,divisor_r};
  assign sub_positive = ~sub_negative;

  assign mask = ~({WIDTH{1'b1}} << cnt); // low bit mask.
  assign dividend = sub_negative ? dividend_r : {{WIDTH{1'b0}}, {(div_sub<<cnt) | (dividend_r[WIDTH-1:0] & mask)}};

  for(genvar i=0; i<WIDTH; i++)begin
    assign quotient[i]  = (i == cnt) ? sub_positive : quotient_r[i];
  end

  // 4. output:
  assign o_quotient  = cntneq0 ? {WIDTH{1'b0}} : (~(dividend_positive^divisor_positive) ? quotient : ~quotient + 1'b1)  ;
  assign o_remainder = cntneq0 ? {WIDTH{1'b0}} : (dividend_positive ? dividend[WIDTH-1:0] : ~dividend[WIDTH-1:0] + 1'b1);

endmodule
