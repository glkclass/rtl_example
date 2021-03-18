
`timescale 1 ns / 1 ps

//TTB. Generate RST, CLK signals. Read inputs, write output from/to file
module ttb;
    localparam 
        RST_INTERVAL = 220,
        CLK_PERIOD = 100,
        N_VALUES = 20, // number of values to be written and read back (actually number of test write/read transactions)

        N_REG = 5, // number of regs
        ADDR_WIDTH = 8, // address width
        DATA_WIDTH = 8; // data width
    localparam 
        [DATA_WIDTH-1 : 0] DATA_VALUE_REG_5 = 8'h33;
    localparam 
        [ADDR_WIDTH-1 : 0] ADDR [N_REG-1 : 0]  = '{8'h55, 8'h06, 8'hA1, 8'h78, 8'h34};  // reg addresses

    localparam 
        [DATA_WIDTH-1 : 0] VALUE [N_VALUES-1 : 0]  = '{
            8'hFF, 8'hEE, 8'hDD, 8'hCC, 8'hBB,
            8'hFF, 8'hEE, 8'hDD, 8'hCC, 8'hBB,
            8'hFF, 8'hEE, 8'hDD, 8'hCC, 8'hBB,
            8'hFF, 8'hEE, 8'hDD, 8'hCC, 8'hBB
        };  // reg values

reg 
    rst = 1'b0, 
    clk = 1'b0,
    wr_en = 1'b0,
    rd_en = 1'b0,
    din = 1'b0,
    dout;

// write single reg
task write_reg(
    input [ADDR_WIDTH-1 : 0] addr, [DATA_WIDTH-1 : 0] value);

    @(posedge clk);
    wr_en = 1'b1;
    
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                wr_en = 1'b0;
            din = addr[ADDR_WIDTH-1-i];
        end

    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            din = value[ADDR_WIDTH-1-i];
        end
endtask

// write 2 regs wo gap
task write_2_reg_wo_gap(
    input [ADDR_WIDTH-1 : 0] addr_0, addr_1, [DATA_WIDTH-1 : 0] value_0, value_1);

    @(posedge clk);
    wr_en = 1'b1;
    
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                wr_en = 1'b0;
            din = addr_0[ADDR_WIDTH-1-i];
        end

    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (7 == i) 
                wr_en = 1'b1;
            din = value_0[ADDR_WIDTH-1-i];
        end

    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                wr_en = 1'b0;
            din = addr_1[ADDR_WIDTH-1-i];
        end

    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            din = value_1[ADDR_WIDTH-1-i];
        end
endtask


// write / read regs
initial begin
    #(2*RST_INTERVAL)
    for (int i = 0; i < 4; i++) 
        begin
            write_reg(ADDR[i], VALUE[i]);
        end

    write_2_reg_wo_gap(ADDR[0], ADDR[1], VALUE[2], VALUE[3]);

end


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
#(
    .N_REG(N_REG),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_VALUE_REG_5(DATA_VALUE_REG_5),
    .ADDR(ADDR)
)

uut
(
    .RSTN(rst),
    .CLK(clk),
    .WR_EN(wr_en),
    .RD_EN(rd_en),
    .DIN(din),
    .DOUT(dout)
);

endmodule
