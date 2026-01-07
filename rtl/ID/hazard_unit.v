`timescale 1ns/1ps


module hazard_unit (
    input ID_EX_MemRead,
    input [4:0] ID_EX_Rt,
    input [4:0] IF_ID_Rs,
    input [4:0] IF_ID_Rt,
    output reg PCWrite,
    output reg IF_ID_Write,
    output reg ID_EX_Flush
);
    always @(*) begin
        if (ID_EX_MemRead &&
           ((ID_EX_Rt == IF_ID_Rs) || (ID_EX_Rt == IF_ID_Rt))) begin
            PCWrite     = 0;
            IF_ID_Write = 0;
            ID_EX_Flush = 1;
        end else begin
            PCWrite     = 1;
            IF_ID_Write = 1;
            ID_EX_Flush = 0;
        end
    end
endmodule
