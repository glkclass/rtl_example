
// sm_core module. Contains main core implementation.
module reg_file
    (
        input 
            RSTN, CLK, RD_EN, WR_EN, DIN,
        
        output 

            DOUT
    );
    localparam
        N_REG = 5, // number of regs
        DATA_WIDTH = 8,
        DATA_VALUE_REG_5 = 8'h33,
        ADDR_WIDTH = 8;

    localparam [ADDR_WIDTH-1 : 0] ADDR [N_REG-1 : 0]  = '{8'h55, 8'h06, 8'hA1, 8'h78, 8'h34};  // reg addresses



reg [4-1 : 0] cnt;
reg [ADDR_WIDTH-1 : 0] addr_reg;
reg [ADDR_WIDTH-1 : 0] data_reg [N_REG-1 : 0] ;



wire addr_shft_en, data_shft_en;

assign addr_shft_en = (cnt < 4'h7) ? 1:0;
assign data_shft_en = (cnt >= 4'h7) ? 1:0;


// write data shift reg. Reg 1..4
genvar ii;
generate
    for (ii = 0; ii < N_REG-1; ii = ii+1)
        begin: g_data_regs
            always @ (posedge CLK, negedge RSTN) 
                begin
                    if (!RSTN) 
                        begin                            
                            data_reg[ii] <= 8'h00;
                        end
                    else 
                        begin
                            if (!addr_shft_en && data_shft_en && ADDR[ii] == addr_reg) 
                                begin 
                                    data_reg[ii][DATA_WIDTH-1 : 0] <= {data_reg[ii][DATA_WIDTH-2 : 0], DIN};
                                end
                        end
                end // always
        end
endgenerate

// read only Reg 5
always @ (posedge CLK, negedge RSTN) 
    begin
        if (!RSTN) 
            begin                            
                data_reg[N_REG-1] <= DATA_VALUE_REG_5;
            end
        else 
            begin
            end
    end // always



// addr shift reg
always @ (posedge CLK, negedge RSTN) 
    begin
        if (!RSTN) 
            begin
                addr_reg <= 8'h00;
            end
        else 
            begin
                if (addr_shft_en) 
                    begin 
                        addr_reg[ADDR_WIDTH-1 : 0] <= {addr_reg[ADDR_WIDTH-2 : 0], DIN};
                    end
            end
    end // always



// WR cycle count
always @ (posedge CLK, negedge RSTN) 
    begin
        if (!RSTN) 
            begin
                cnt <= 4'h0;
            end
        else 
            begin
                if (WR_EN) 
                    begin 
                        cnt <= 4'hF;
                    end
                else
                    begin 
                        if (4'h0 != cnt) 
                            begin 
                                cnt <= cnt + 4'h1;
                            end
                    end
            end
    end // always








endmodule
