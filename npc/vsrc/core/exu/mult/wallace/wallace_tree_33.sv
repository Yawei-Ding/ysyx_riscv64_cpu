module wallace_tree_33 #(
  parameter WIDTH=132
) (
  input  [WIDTH-1:0] in [32:0],
  output [WIDTH-1:0] out[1:0]
);

  wire  [WIDTH-1:0] s_row1[11:0];
  wire  [WIDTH-1:0] c_row1[11:0];
  wire  [WIDTH-1:0] c_row1_shift[11:0];

  wire  [WIDTH-1:0] s_row2[6:0];
  wire  [WIDTH-1:0] c_row2[6:0];
  wire  [WIDTH-1:0] c_row2_shift[6:0];
  
  wire  [WIDTH-1:0] s_row3[4:0];
  wire  [WIDTH-1:0] c_row3[4:0];
  wire  [WIDTH-1:0] c_row3_shift[4:0];

  wire  [WIDTH-1:0] s_row4[2:0];
  wire  [WIDTH-1:0] c_row4[2:0];
  wire  [WIDTH-1:0] c_row4_shift[2:0];

  wire  [WIDTH-1:0] s_row5[1:0];
  wire  [WIDTH-1:0] c_row5[1:0];
  wire  [WIDTH-1:0] c_row5_shift[1:0];

  wire  [WIDTH-1:0] s_row6, c_row6, c_row6_shift;
  wire  [WIDTH-1:0] s_row7, c_row7, c_row7_shift;
  wire  [WIDTH-1:0] s_row8, c_row8, c_row8_shift;

  // 1. first level, 11 csa, 33p -> 22p://////////////////////////////////////////////////////////////
  for(genvar i=0; i<11; i=i+1)begin: csa_row1
    csa_nbit #(.N(WIDTH)) csa_row1  (in[3*i] , in[3*i+1] , in[3*i+2] , s_row1[i], c_row1[i]);
    assign c_row1_shift[i] = {c_row1[i][WIDTH-2:0], 1'b0};
  end

  // 2. second level, 7 csa, 22p -> 15p (2*7+1):///////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row2_0  (s_row1[0]      , c_row1_shift[0],  s_row1[1]      ,  s_row2[0], c_row2[0]);
  csa_nbit #(.N(WIDTH)) csa_row2_1  (c_row1_shift[1], s_row1[2]      ,  c_row1_shift[2],  s_row2[1], c_row2[1]);
  csa_nbit #(.N(WIDTH)) csa_row2_2  (s_row1[3]      , c_row1_shift[3],  s_row1[4]      ,  s_row2[2], c_row2[2]);
  csa_nbit #(.N(WIDTH)) csa_row2_3  (c_row1_shift[4], s_row1[5]      ,  c_row1_shift[5],  s_row2[3], c_row2[3]);
  csa_nbit #(.N(WIDTH)) csa_row2_4  (s_row1[6]      , c_row1_shift[6],  s_row1[7]      ,  s_row2[4], c_row2[4]);
  csa_nbit #(.N(WIDTH)) csa_row2_5  (c_row1_shift[7], s_row1[8]      ,  c_row1_shift[8],  s_row2[5], c_row2[5]);
  csa_nbit #(.N(WIDTH)) csa_row2_6  (s_row1[9]      , c_row1_shift[9],  s_row1[10]     ,  s_row2[6], c_row2[6]);
  for(genvar i=0; i<7; i=i+1)begin: csa_row2_shift
    assign c_row2_shift[i] = {c_row2[i][WIDTH-2:0], 1'b0};
  end

  // 3. third level, 5 csa, 15p -> 10p: ///////////////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row3_0  (c_row1_shift[10], s_row2[0]      , c_row2_shift[0], s_row3[0], c_row3[0]);
  csa_nbit #(.N(WIDTH)) csa_row3_1  (s_row2[1]       , c_row2_shift[1], s_row2[2]      , s_row3[1], c_row3[1]);
  csa_nbit #(.N(WIDTH)) csa_row3_2  (c_row2_shift[2] , s_row2[3]      , c_row2_shift[3], s_row3[2], c_row3[2]);
  csa_nbit #(.N(WIDTH)) csa_row3_3  (s_row2[4]       , c_row2_shift[4], s_row2[5]      , s_row3[3], c_row3[3]);
  csa_nbit #(.N(WIDTH)) csa_row3_4  (c_row2_shift[5] , s_row2[6]      , c_row2_shift[6], s_row3[4], c_row3[4]);
  for(genvar i=0; i<5; i=i+1)begin: csa_row3_shift
    assign c_row3_shift[i] = {c_row3[i][WIDTH-2:0], 1'b0};
  end

  // 4. fourth level, 3 csa, 10p -> 7p (2*3+1): ////////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row4_0  (s_row3[0]       , c_row3_shift[0], s_row3[1]      , s_row4[0], c_row4[0]);
  csa_nbit #(.N(WIDTH)) csa_row4_1  (c_row3_shift[1] , s_row3[2]      , c_row3_shift[2], s_row4[1], c_row4[1]);
  csa_nbit #(.N(WIDTH)) csa_row4_2  (s_row3[3]       , c_row3_shift[3], s_row3[4]      , s_row4[2], c_row4[2]);
  for(genvar i=0; i<3; i=i+1)begin: csa_row4_shift
    assign c_row4_shift[i] = {c_row4[i][WIDTH-2:0], 1'b0};
  end

  // 5. fifth level, 2 csa, 7p -> 5p (2*2+1): //////////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row5_0  (c_row3_shift[4], s_row4[0]      , c_row4_shift[0], s_row5[0], c_row5[0]);
  csa_nbit #(.N(WIDTH)) csa_row5_1  (s_row4[1]      , c_row4_shift[1], s_row4[2]      , s_row5[1], c_row5[1]);
  for(genvar i=0; i<2; i=i+1)begin: csa_row5_shift
    assign c_row5_shift[i] = {c_row5[i][WIDTH-2:0], 1'b0};
  end

  // 6. sixth level, 1 csa, 5p -> 4p (2+2): ////////////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row6    (c_row4_shift[2], s_row5[0], c_row5_shift[0], s_row6, c_row6);
  assign c_row6_shift = {c_row6[WIDTH-2:0], 1'b0};

  // 7. seventh level, 1 csa, 4p -> 3p (2+1): //////////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row7    (s_row5[1], c_row5_shift[1], s_row6, s_row7, c_row7);
  assign c_row7_shift = {c_row7[WIDTH-2:0], 1'b0};

  // 8. eighth level, 1 csa, 3p -> 2p: ////////////////////////////////////////////////////////////////////
  csa_nbit #(.N(WIDTH)) csa_row8    (c_row6_shift, s_row7, c_row7_shift, s_row8, c_row8);
  assign c_row8_shift = {c_row8[WIDTH-2:0], 1'b0};

  // 9. output 2p :////////////////////////////////////////////////////////////////////////////////////////
  assign out[1] = c_row8_shift;
  assign out[0] = s_row8;

endmodule
