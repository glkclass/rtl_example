
// sm_core module. Contains main core implementation.
module reg_file
    #(
        parameter
            N_REG = 5, // number of regs
            ADDR_WIDTH = 8, // address width
            DATA_WIDTH = 8, // data width
        parameter
            [DATA_WIDTH-1 : 0] DATA_VALUE_REG_5 = 8'h33, // REG_5 init value (read only)
        parameter 
            [ADDR_WIDTH-1 : 0] ADDR [N_REG-1 : 0]  = '{8'h55, 8'h06, 8'hA1, 8'h78, 8'h34}  // default reg addresses    
    )
    (
        input 
            RSTN, CLK, RD_EN, WR_EN, DIN,
        output 
            DOUT
    );

reg [4-1 : 0] cnt;
reg [ADDR_WIDTH-1 : 0] addr_reg;
reg [ADDR_WIDTH-1 : 0] data_reg [N_REG-1 : 0] ;
reg data_shft_en_1;

wire addr_shft_en, data_shft_en, data_shft_en_0;


assign addr_shft_en = (cnt > 4'h7) ? 1:0;
assign data_shft_en_0 = (cnt > 4'h0 && cnt <= 4'h7) ? 1:0;
assign data_shft_en = data_shft_en_0 || data_shft_en_1;

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



// write/read cycle count
always @ (posedge CLK, negedge RSTN) 
    begin
        if (!RSTN) 
            begin
                cnt <= 4'h0;
                data_shft_en_1 <= 1'b0;
            end
        else 
            begin
                data_shft_en_1 <= data_shft_en_0; // 1 cycle delay for data writing

                if (WR_EN) 
                    begin 
                        cnt <= 4'hF;
                    end
                else
                    begin 
                        if (4'h0 != cnt) 
                            begin 
                                cnt <= cnt - 4'h1;
                            end
                    end
            end
    end // always








endmodule
