`timescale 1ns / 1ps



module instruction_memory (
    input [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:255];

    initial begin
        $readmemh("instr_mem.hex", mem);
    end

    assign instr = mem[addr[9:2]]; // word aligned
endmodule
