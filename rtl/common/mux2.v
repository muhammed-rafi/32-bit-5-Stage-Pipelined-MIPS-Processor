`timescale 1ns / 1ps

module mux2 #(parameter W = 32)(
    input  [W-1:0] a,
    input  [W-1:0] b,
    input          sel,
    output [W-1:0] y
);
    assign y = sel ? b : a;
endmodule
