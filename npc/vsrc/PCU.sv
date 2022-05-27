`include "define.sv"
module PCU (
    input                         rst_n,
    input                         brch ,  
    input                         jal  ,
    input                         jalr ,
    input                         rs1  ,
    input                         ALUO ,
    input        [`CPU_WIDTH-1:0] imm  ,     
    output logic [`CPU_WIDTH-1:0] pc
);

  wire [`CPU_WIDTH-1:0] next_pc;

  always @(*) begin
    if (brch && ALUO) begin
      next_pc = pc + imm;
    end else if (jal) begin
      next_pc = pc + imm;  
    end else if (jalr) begin
      next_pc = rs1 + imm;
    end else begin
      next_pc = pc + 4;
    end
  end

  always@(posedge clk)begin
    if(!rst_n)begin
      pc <= {32'b0,'h80000000};
    end else begin
      pc <= next_pc;
    end
  end

endmodule
