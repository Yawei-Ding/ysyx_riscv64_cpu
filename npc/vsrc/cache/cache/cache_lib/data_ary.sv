module data_ary(
  input               i_clk  ,
  input               i_rst_n,
  input               i_ren  ,
  input               i_wen  ,
  input       [ 15:0] i_wstrb,
  input       [  6:0] i_addr , // 7 bit, 128 depth.
  input       [127:0] i_wdata,
  output      [127:0] o_rdata
);

  // 1. control signals:///////////////////////////////////////////////////////////////
  logic [1:0] wen_exten, ren_exten;
  logic [1:0] WEN_EXTEN, CEN_EXTEN;

  assign wen_exten = {i_addr[6], ~i_addr[6]} & {2{i_wen}};
  assign ren_exten = {i_addr[6], ~i_addr[6]} & {2{i_ren}};
  assign WEN_EXTEN = ~ wen_exten;
  assign CEN_EXTEN = ~ {ren_exten | wen_exten};

  logic [127:0] BWEN;

  for (genvar i=0; i<16 ; i=i+1 ) begin
    assign BWEN[8*i+7 : 8*i] = {8{~i_wstrb[i]}};
  end

  // 2. sram (addr) extension: ////////////////////////////////////////////////////////

  logic [127:0] Q_EXTEN [1:0];

  for(genvar i=0; i<2; i++)begin
      S011HD1P_X32Y2D128_BW  #(
      .Bits       (128),
      .Word_Depth (64 ),
      .Add_Width  (6  ),
      .Wen_Width  (128)
    ) u_sram_high (
      .CLK  (i_clk        ),
      .CEN  (CEN_EXTEN[i] ),
      .WEN  (WEN_EXTEN[i] ),
      .BWEN (BWEN         ),
      .A    (i_addr[5:0]  ),
      .D    (i_wdata      ),
      .Q    (Q_EXTEN[i]   )
    );
  end

  // 3. get rdata://////////////////////////////////////////////////////////////////////////

  logic [1:0] ren_exten_r;

  stl_reg #(
    .WIDTH      (2          ), 
    .RESET_VAL  (2'b00      )
  ) reg_ren (
  	.i_clk      (i_clk      ), 
    .i_rst_n    (i_rst_n    ), 
    .i_wen      (1'b1       ), 
    .i_din      (ren_exten  ), 
    .o_dout     (ren_exten_r)
  );

  assign o_rdata = ren_exten_r[1] ? Q_EXTEN[1] : (ren_exten_r[0] ? Q_EXTEN[0] : 128'b0);

endmodule
