`timescale 1ns / 1ps

module data_memory (
    input clk,
    input MemRead,
    input MemWrite,
    input [31:0] addr,
    input [31:0] wd,
    output [31:0] rd
);
    reg [31:0] mem [0:255];

    assign rd = MemRead ? mem[addr[9:2]] : 32'b0;

    always @(posedge clk) begin
        if (MemWrite)
            mem[addr[9:2]] <= wd;
    end
endmodule
