`timescale 1ns/1ps



module EX_MEM_reg (
    input clk,
    input rst,
    input RegWrite_in, MemRead_in, MemWrite_in, MemToReg_in,
    input [31:0] alu_out_in,
    input [31:0] rt_data_in,
    input [4:0] rd_in,

    output reg RegWrite, MemRead, MemWrite, MemToReg,
    output reg [31:0] alu_out,
    output reg [31:0] rt_data,
    output reg [4:0] rd
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RegWrite <= 0;
            MemRead  <= 0;
            MemWrite <= 0;
            MemToReg <= 0;
        end else begin
            RegWrite <= RegWrite_in;
            MemRead  <= MemRead_in;
            MemWrite <= MemWrite_in;
            MemToReg <= MemToReg_in;
            alu_out  <= alu_out_in;
            rt_data  <= rt_data_in;
            rd       <= rd_in;
        end
    end
endmodule
