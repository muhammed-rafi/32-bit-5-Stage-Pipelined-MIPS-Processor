

module tb_top_mips;
    reg clk;
    reg rst;

    top_mips dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #20 rst = 0;
        #500 $finish;
    end
endmodule
