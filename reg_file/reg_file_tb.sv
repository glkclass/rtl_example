//TTB. Generate RST, CLK signals. Read inputs, write output from/to file
module ttb;
    localparam 
        RST_INTERVAL = 220,
        CLK_PERIOD = 100,
        N_VALUES = 10, // number of different reg values to be written and read back

        N_REG = 5, // number of regs
        ADDR_WIDTH = 8, // address width
        DATA_WIDTH = 8; // data width
    localparam 
        [DATA_WIDTH-1 : 0] DATA_VALUE_REG_5 = 8'h33;
    localparam 
        [ADDR_WIDTH-1 : 0] ADDR [N_REG-1 : 0]  = '{8'h55, 8'h06, 8'hA1, 8'h78, 8'h34};  // reg addresses

    localparam 
        [DATA_WIDTH-1 : 0] VALUE [N_VALUES-1 : 0]  = '{
            8'hFF, 8'hEE, 8'hDD, 8'h81, 8'h00,
            8'hAA, 8'h55, 8'h00, 8'h01, 8'h10
        };  // reg values

// hash to check write/read results
bit [DATA_WIDTH-1 : 0] reg_copy[bit [ADDR_WIDTH-1 : 0]];

reg 
    rst = 1'b0, 
    clk = 1'b0,
    wr_en = 1'b0,
    rd_en = 1'b0,
    din = 1'b0,
    dout;

reg [DATA_WIDTH-1 : 0] 
    value = 8'h00, 
    value_0 = 8'h00, 
    value_1 = 8'h00;

task store2reg_copy(
    input [ADDR_WIDTH-1 : 0] addr, [DATA_WIDTH-1 : 0] data);
    if (ADDR[N_REG-1] != addr) // read only reg
        begin
            reg_copy[addr] = data;
        end
endtask


// read single reg
task read_reg(
    input [ADDR_WIDTH-1 : 0] addr);

    @(posedge clk);
    rd_en = 1'b1;
    
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                rd_en = 1'b0;
            din = addr[ADDR_WIDTH-1-i];
        end

    @(posedge clk);
    din = 1'b0;
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            value[DATA_WIDTH-1-i] = dout;
        end
    $display ("%t: Read value: 0x%H from REG[0x%H]", $time, value, addr);
    if (value != reg_copy[addr])
        $error ("%t: Read value: 0x%H from REG[0x%H]. Expected: 0x%H", $time, value, addr, reg_copy[addr]);
endtask

task read_2_reg_wo_gap(
    input [ADDR_WIDTH-1 : 0] addr_0, addr_1);

    @(posedge clk);
    rd_en = 1'b1;
    
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                rd_en = 1'b0;
            din = addr_0[ADDR_WIDTH-1-i];
        end

    @(posedge clk);
    din = 1'b0;
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (7 == i) 
                rd_en = 1'b1;
            value_0[DATA_WIDTH-1-i] = dout;
        end

    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                rd_en = 1'b0;
            din = addr_1[ADDR_WIDTH-1-i];
        end

    @(posedge clk);
    din = 1'b0;
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            value_1[DATA_WIDTH-1-i] = dout;
        end

    $display ("%t: Read value: 0x%H from REG[0x%H]", $time, value_0, addr_0);
    $display ("%t: Read value: 0x%H from REG[0x%H]", $time, value_1, addr_1);

    if (value_0 != reg_copy[addr_0])
        $error ("%t: Read value: 0x%H from REG[0x%H]. Expected: 0x%H", $time, value_0, addr_0, reg_copy[addr_0]);

    if (value_1 != reg_copy[addr_1])
        $error ("%t: Read value: 0x%H from REG[0x%H]. Expected: 0x%H", $time, value_1, addr_1, reg_copy[addr_1]);
endtask

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
            din = value[DATA_WIDTH-1-i];
        end
    @(posedge clk);
    din = 1'b0;
    
    store2reg_copy(addr, value);
    $display ("%t: Write value: 0x%H to REG[0x%H]", $time, value, addr);
endtask

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
            din = value_0[DATA_WIDTH-1-i];
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
            din = value_1[DATA_WIDTH-1-i];
        end

    @(posedge clk);
    din = 1'b0;

    store2reg_copy(addr_0, value_0);
    store2reg_copy(addr_1, value_1);

    $display ("%t: Write value: 0x%H to REG[0x%H]", $time, value_0, addr_0);
    $display ("%t: Write value: 0x%H to REG[0x%H]", $time, value_1, addr_1);

endtask

task write_read_wo_gap(
    input [ADDR_WIDTH-1 : 0] addr_0, addr_1, [DATA_WIDTH-1 : 0] value_0);

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
                rd_en = 1'b1;
            din = value_0[DATA_WIDTH-1-i];
        end

    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            if (0 == i) 
                rd_en = 1'b0;
            din = addr_1[ADDR_WIDTH-1-i];
        end

    @(posedge clk);
    din = 1'b0;
    
    for (int i = 0; i < 8; i++)
        begin
            @(posedge clk);
            value_1[DATA_WIDTH-1-i] = dout;
        end

    store2reg_copy(addr_0, value_0);
    $display ("%t: Write value: 0x%H to REG[0x%H]", $time, value_0, addr_0);
    $display ("%t: Read value: 0x%H from REG[0x%H]", $time, value_1, addr_1);

    if (value_1 != reg_copy[addr_1])
        $error ("%t: Read value: 0x%H from REG[0x%H]. Expected: 0x%H", $time, value_1, addr_1, reg_copy[addr_1]);   
endtask

// write / read regs
initial begin
    #(2*RST_INTERVAL)
    reg_copy[ADDR[N_REG-1]] = DATA_VALUE_REG_5; // init read only reg_copy

    write_reg(ADDR[0], VALUE[0]);
    read_reg(ADDR[0]);

    for (int i = 0; i < 5; i++) 
        begin
            write_reg(ADDR[i], VALUE[i]);
        end

    for (int i = 0; i < 5; i++) 
        begin
            read_reg(ADDR[i]);
        end
    
    write_2_reg_wo_gap(ADDR[0], ADDR[1], VALUE[2], VALUE[3]);
    read_reg(ADDR[0]);
    read_reg(ADDR[1]);
    
    write_read_wo_gap(ADDR[2], ADDR[3], VALUE[2]);

    read_2_reg_wo_gap(ADDR[0], ADDR[1]);

    for (int i = 0; i < 5; i++) 
        begin
            write_reg(ADDR[i], VALUE[5 + i]);
            repeat(5)
                @(posedge clk);
            read_reg(ADDR[i]);
        end
    $display("The End");
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
