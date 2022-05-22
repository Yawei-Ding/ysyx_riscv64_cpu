module reset(
	input   clk        , // 输入时钟
	input   rst_n      , // 输入异步复位信号
	output  rst_n_sync   // 输出同步释放后的复位信号
);

	reg      rst_n_r1 ; // 第1级寄存器
	reg      rst_n_r2 ; // 第2级寄存器

	assign rst_n_sync = rst_n_r2 ;

	always @ (posedge clk or negedge rst_n) begin
		if (~rst_n) begin
				rst_n_r1 <= 1'b0 ; 
				rst_n_r2 <= 1'b0 ; // 复位信号有效时拉低
		end // 
		else begin
				rst_n_r1 <= 1'b1    ; 
				rst_n_r2 <= rst_n_r1; // 复位信号无效后，通过两级打拍，实现释放同步
		end
	end

endmodule
