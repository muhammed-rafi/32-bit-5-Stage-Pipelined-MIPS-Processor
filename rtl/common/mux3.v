`timescale 1ns / 1ps

module mux3x32to32 (
    output reg [31:0] y,
    input  [31:0] a,   // 00: from ID/EX
    input  [31:0] b,   // 10: from EX/MEM
    input  [31:0] c,   // 01: from MEM/WB
    input  [1:0]  sel
);

    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = c;
            2'b10: y = b;
            default: y = a;
        endcase
    end

endmodule
