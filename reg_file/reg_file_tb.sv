
`timescale 1 ns / 1 ps

//TTB. Generate RST, CLK signals. Read inputs, write output from/to file
module ttb;
    localparam 
        RST_INTERVAL = 220,
        CLK_PERIOD = 100;

reg 
    rst = 1'b0, 
    clk = 1'b0,
    wr_en = 1'b0,
    rd_en = 1'b0,
    din = 1'b0,
    dout;

// RST
initial begin
    rst = 1'b0;
    #(RST_INTERVAL) rst = 1'b1;
end

// CLK
initial begin
    clk = 1'b0;
    forever
        #(CLK_PERIOD/2) clk = ~clk;
end


reg_file
UUT
(
    .RSTN(rst),
    .CLK(clk),
    .WR_EN(wr_en),
    .RD_EN(rd_en),
    .DIN(din),
    .DOUT(dou)
);

endmodule
