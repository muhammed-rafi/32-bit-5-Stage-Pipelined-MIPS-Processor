`timescale 1ns / 1ps

module ID_EX_reg (
    input clk,
    input rst,
    input flush,
    input RegWrite_in, MemRead_in, MemWrite_in,
    input MemToReg_in, ALUSrc_in,
    input [1:0] ALUOp_in,
    input [31:0] rd1_in, rd2_in, imm_in,
    input [4:0] rs_in, rt_in, rd_in,

    output reg RegWrite, MemRead, MemWrite,
    output reg MemToReg, ALUSrc,
    output reg [1:0] ALUOp,
    output reg [31:0] rd1, rd2, imm,
    output reg [4:0] rs, rt, rd
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            RegWrite <= 0;
            MemRead  <= 0;
            MemWrite <= 0;
        end else begin
            RegWrite <= RegWrite_in;
            MemRead  <= MemRead_in;
            MemWrite <= MemWrite_in;
            MemToReg <= MemToReg_in;
            ALUSrc   <= ALUSrc_in;
            ALUOp    <= ALUOp_in;
            rd1 <= rd1_in;
            rd2 <= rd2_in;
            imm <= imm_in;
            rs  <= rs_in;
            rt  <= rt_in;
            rd  <= rd_in;
        end
    end
endmodule
