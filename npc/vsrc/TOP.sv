`include "define.sv"
module TOP(
  input                               clk                        ,
  input                               rst_n                      ,
  input              [  31:0]         ins                        ,
  output                              logic [63:0] pc             
);
  //1.rst : ////////////////////////////////////////////////////////
  logic rst_n_sync;//rst_n for whole cpu!!
  Rst u_Rst(
  	.clk        (clk        ),
    .rst_n      (rst_n      ),
    .rst_n_sync (rst_n_sync )
  );

  //2.regsister:  ////////////////////////////////////////////////




  //sim:  ////////////////////////////////////////////////////////
  import "DPI-C" function bit check_finsih(input int finish_flag);
  always@(*)begin
    if(check_finsih(ins))begin
      $finish;
      $display("HIT GOOD TRAP!!");
    end
  end

endmodule
