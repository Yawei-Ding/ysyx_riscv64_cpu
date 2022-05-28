`include "vsrc/lib/define.sv"
module pcu (
    input                         clk  ,
    input                         rst_n,
    input                         brch ,
    input                         jal  ,
    input                         jalr ,
    input                         zero ,
    input        [`CPU_WIDTH-1:0] rs1  ,
    input        [`CPU_WIDTH-1:0] imm  ,
    output logic [`CPU_WIDTH-1:0] pc
);

  logic [`CPU_WIDTH-1:0] next_pc;

  always @(*) begin
    if (brch && ~zero) begin
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
