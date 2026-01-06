`timescale 1ns / 1ps



module pc (
    input clk,
    input rst,
    input pc_write,
    input [31:0] pc_next,
    output reg [31:0] pc
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'b0;
        else if (pc_write)
            pc <= pc_next;
    end
endmodule

