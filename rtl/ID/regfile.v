`timescale 1ns / 1ps

module regfile (
    input clk,
    input we,
    input [4:0] ra1, ra2, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2
);
    reg [31:0] regs [0:31];

    assign rd1 = (ra1 != 0) ? regs[ra1] : 0;
    assign rd2 = (ra2 != 0) ? regs[ra2] : 0;

    always @(posedge clk) begin
        if (we && wa != 0)
            regs[wa] <= wd;
    end
endmodule
