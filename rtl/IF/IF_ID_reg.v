`timescale 1ns / 1ps



module IF_ID_reg (
    input clk,
    input rst,
    input write_en,
    input flush,
    input [31:0] pc_plus4_in,
    input [31:0] instr_in,
    output reg [31:0] pc_plus4_out,
    output reg [31:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_plus4_out <= 0;
            instr_out    <= 0;
        end else if (write_en) begin
            pc_plus4_out <= pc_plus4_in;
            instr_out    <= instr_in;
        end
    end
endmodule

