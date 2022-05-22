`include "vsrc/define.sv"
module top(
  input clk,
  input rst_n,
  input [31:0] inst,
  output logic [63:0] pc
);

  logic rst_n_sync;
  logic [6:0] opcode,func7;
  logic [2:0] func3;
  logic [4:0] rs1id,rs2id,rdid;
  logic [63:0] imm,rs1,rs2,rd;

  //译码：
  assign opcode = inst[6:0];
  always@(*)begin
    imm = 64'b0;
    func7 = 7'b0;
    func3 = 3'b0;
    rs2id = 5'b0;
    rs1id = 5'b0;
    rdid  = 5'b0; 
    case(opcode) // I-type:
      `TYPE_I:begin imm = {{52{inst[31]}},inst[31:20]}; rs1id = inst[19:15]; func3 = inst[14:12]; rdid  = inst[11:7]; end
      default:begin end
    endcase
  end

  always@(posedge clk)begin
    if(!rst_n_sync)begin
      rd <= 0;
      pc <= {32'b0,'h80000000};
    end else begin
      case(opcode)
        `TYPE_I:begin
          rd <= rs1 + imm;
          pc <= pc + 4;
        end
        default:begin
          rd <= 0;
          pc <= pc;
        end
      endcase
    end
  end

  logic RFwen,RFren;
  assign RFwen = (opcode == `TYPE_I);
  assign RFren = 1;
  RegsisterFile#(
    .REG_COUNT(32),
    .DATA_WIDTH(64)
  )RegFile(
    .clk(clk),
    .wen(RFwen),
    .ren(RFren),
    .waddr(rdid),
    .wdata(rd),
    .raddr1(rs1id),
    .raddr2(rs2id),
    .rdata1(rs1),
    .rdata2(rs2)
  );

  reset rst(
    .clk(clk),
    .rst_n(rst_n),
    .rst_n_sync(rst_n_sync)
  );

  //---------------------------start for sim : --------------------------//
  import "DPI-C" function bit check_finsih(input int finish_flag);

  always@(*)begin
    if(check_finsih(inst))begin
      $finish;
      $display("HIT GOOD TRAP!!");
    end
  end
  //---------------------------  end for sim  --------------------------//
  
endmodule
