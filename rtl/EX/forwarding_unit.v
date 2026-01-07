`timescale 1ns / 1ps


module forwarding_unit (
    input EX_MEM_RegWrite,
    input MEM_WB_RegWrite,
    input [4:0] EX_MEM_Rd,
    input [4:0] MEM_WB_Rd,
    input [4:0] ID_EX_Rs,
    input [4:0] ID_EX_Rt,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);
    always @(*) begin
        ForwardA = 2'b00;
        ForwardB = 2'b00;

        if (EX_MEM_RegWrite && EX_MEM_Rd != 0 && EX_MEM_Rd == ID_EX_Rs)
            ForwardA = 2'b10;

        if (EX_MEM_RegWrite && EX_MEM_Rd != 0 && EX_MEM_Rd == ID_EX_Rt)
            ForwardB = 2'b10;

        if (MEM_WB_RegWrite && MEM_WB_Rd != 0 &&
            !(EX_MEM_RegWrite && EX_MEM_Rd == ID_EX_Rs) &&
            MEM_WB_Rd == ID_EX_Rs)
            ForwardA = 2'b01;

        if (MEM_WB_RegWrite && MEM_WB_Rd != 0 &&
            !(EX_MEM_RegWrite && EX_MEM_Rd == ID_EX_Rt) &&
            MEM_WB_Rd == ID_EX_Rt)
            ForwardB = 2'b01;
    end
endmodule
