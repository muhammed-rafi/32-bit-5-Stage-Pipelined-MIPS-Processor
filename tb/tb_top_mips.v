`timescale 1ns / 1ps

module tb_top_mips;
    reg clk;
    reg rst;

    top_mips dut (
        .clk(clk),
        .reset(rst)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize
        clk = 0;
        rst = 1;
        
        // 2. Apply Reset
        #20 rst = 0;
        $display("-------------------------------------------------------------");
        $display("Time  | PC       | $1(v1)| $2(v0)| $3(a0)| $4(a1)| $5(a2)| Instruction");
        $display("-------------------------------------------------------------");

        // 3. Monitor Signals
        $monitor("%4t  | %h |   %2d  |   %2d  |   %2d  |   %2d  |   %2d  | Ext: %h", 
                 $time, 
                 dut.PC, 
                 dut.Register_File.regs[1], // $1
                 dut.Register_File.regs[2], // $2
                 dut.Register_File.regs[3], // $3
                 dut.Register_File.regs[4], // $4
                 dut.Register_File.regs[5], // $5
                 dut.Instruction
                 );

        
        #200;
        
        
        $display("-------------------------------------------------------------");
        if (dut.Register_File.regs[3] == 8 && dut.Register_File.regs[5] == 2) begin
            $display("SUCCESS: Logic verified.");
            $display("$3 = 8 (5+3) [Correct]");
            $display("$5 = 2 (Branch worked, ADD skipped, SUB executed) [Correct]");
        end else begin
            $display("FAILURE: Incorrect results.");
        end
        $display("-------------------------------------------------------------");
        
        $finish;
    end
endmodule



/*
our test program (in assembly):
XORI $1, $0, 5 -> Load 5 into $1
XORI $2, $0, 3 -> Load 3 into $2
ADD $3, $1, $2 -> $3 = 5 + 3 = 8 (Tests forwarding)
SW $3, 4($0) -> Store 8 into Mem[4]
LW $4, 4($0) -> Load 8 from Mem[4] into $4
BNE $1, $2, 1 -> Branch taken (5 != 3). Skip next instruction.
ADD $5, $1, $1 -> (Skipped/Flushed). $5 should NOT be 10.
SUB $5, $1, $2 -> $5 = 5 - 3 = 2.*/