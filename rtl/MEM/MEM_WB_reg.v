`timescale 1ns / 1ps


module MEM_WB_reg (
    input clk,
    input rst,
    input RegWrite_in,
    input MemToReg_in,
    input [31:0] mem_data_in,
    input [31:0] alu_out_in,
    input [4:0] rd_in,

    output reg RegWrite,
    output reg MemToReg,
    output reg [31:0] mem_data,
    output reg [31:0] alu_out,
    output reg [4:0] rd
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RegWrite <= 0;
            MemToReg <= 0;
        end else begin
            RegWrite <= RegWrite_in;
            MemToReg <= MemToReg_in;
            mem_data <= mem_data_in;
            alu_out  <= alu_out_in;
            rd       <= rd_in;
        end
    end
endmodule
