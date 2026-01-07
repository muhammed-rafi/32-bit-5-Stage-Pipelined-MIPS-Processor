`timescale 1ns / 1ps

module alu_control (
    input  [1:0] ALUOp,
    input  [5:0] funct,
    output reg [3:0] alu_ctrl
);
    always @(*) begin
        case (ALUOp)
            2'b00: alu_ctrl = 4'b0010; // LW, SW
            2'b01: alu_ctrl = 4'b0110; // BEQ
            2'b10: begin
                case (funct)
                    6'b100000: alu_ctrl = 4'b0010; // ADD
                    6'b100010: alu_ctrl = 4'b0110; // SUB
                    6'b100100: alu_ctrl = 4'b0000; // AND
                    6'b100101: alu_ctrl = 4'b0001; // OR
                    6'b101010: alu_ctrl = 4'b0111; // SLT
                    default:   alu_ctrl = 4'b0000;
                endcase
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule
