`include "vsrc/lib/define.sv"
module pcu (
    input                         i_clk  ,
    input                         i_rst_n,
    input                         i_brch ,
    input                         i_jal  ,
    input                         i_jalr ,
    input                         i_zero ,
    input        [`CPU_WIDTH-1:0] i_rs1  ,
    input        [`CPU_WIDTH-1:0] i_imm  ,
    output logic [`CPU_WIDTH-1:0] o_pc
);

  logic [`CPU_WIDTH-1:0] pc_next;

  assign pc_next = (i_brch && ~i_zero || i_jal) ? (o_pc + i_imm) : (i_jalr ? (i_rs1 + i_imm) : (o_pc + 4) );

  always@(posedge i_clk or negedge i_rst_n)begin
    if(!i_rst_n)begin
      o_pc <= {32'b0,'h80000000};
    end else begin
      o_pc <= pc_next;
    end
  end

endmodule
