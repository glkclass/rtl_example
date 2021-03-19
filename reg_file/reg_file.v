module reg_file
    #(
        parameter
            N_REG = 5, // number of regs
            ADDR_WIDTH = 8, // address width
            DATA_WIDTH = 8, // data width
        parameter
            [DATA_WIDTH-1 : 0] DATA_VALUE_REG_5 = 8'h33, // REG_5 init value (read only)
        parameter 
            [N_REG*ADDR_WIDTH-1 : 0] ADDR = 40'h5506A17834  // default reg addresses
    )
    (
        input 
            RSTN, CLK, RD_EN, WR_EN, DIN,
        output reg
            DOUT
    );


reg [4-1 : 0] cnt;
reg [ADDR_WIDTH-1 : 0] addr_reg;
reg [DATA_WIDTH-1 : 0] data_reg [N_REG-1 : 0] ;
reg 
    wr_stage, 
    data_shft_en_1;

wire addr_shft_en, 
    addr0_shft_en, 
    data_shft_en_0;

wire [ADDR_WIDTH-1 : 0] addr;

assign addr_shft_en = (cnt > 4'h8) ? 1:0;
assign addr0_shft_en = (cnt == 4'h8) ? 1:0;
assign data_shft_en_0 = (cnt > 4'h0 && cnt <= 4'h8) ? 1:0;
assign addr = {addr_reg[ADDR_WIDTH-1 : 1], (1'b1 == addr0_shft_en) ? DIN : addr_reg[0]};

// write/read data shift reg. Reg #1..5
genvar ii;
generate
    for (ii = 0; ii < N_REG; ii = ii+1)
        begin: g_data_regs
            always @ (posedge CLK, negedge RSTN) 
                begin
                    if (!RSTN) 
                        begin                            
                            if (4 != ii)
                                data_reg[ii] <= 8'h00;
                            else
                                data_reg[ii] <= DATA_VALUE_REG_5;
                        end
                    else 
                        begin
                            if (wr_stage) 
                                begin 
                                    if (N_REG-1 != ii) // Reg #5 is read only
                                        begin
                                            if (1'b1 == data_shft_en_1 && ADDR[(ii+1)*ADDR_WIDTH-1 : ii*ADDR_WIDTH] == addr) 
                                                begin
                                                    data_reg[ii][DATA_WIDTH-1 : 0] <= {data_reg[ii][DATA_WIDTH-2 : 0], DIN};
                                                end
                                        end
                                end
                            else
                                begin
                                    if (1'b1 == data_shft_en_0 && ADDR[(ii+1)*ADDR_WIDTH-1 : ii*ADDR_WIDTH] == addr) 
                                        begin
                                            // cyclic reg shift. To keep written data after read (shift out).
                                            data_reg[ii][DATA_WIDTH-1 : 0] <= {data_reg[ii][DATA_WIDTH-2 : 0], data_reg[ii][DATA_WIDTH-1]};
                                        end
                                end                            
                        end
                end // always
        end
endgenerate

// DOUT
always @ (posedge CLK, negedge RSTN) 
    begin
        if (!RSTN) 
            begin
                DOUT <= 1'b0;
            end
        else 
            begin
                case ( { wr_stage, data_shft_en_0, addr } )
                    {1'b0, 1'b1, ADDR[ADDR_WIDTH-1 : 0]}: DOUT <= data_reg[0][DATA_WIDTH-1];
                    {1'b0, 1'b1, ADDR[2*ADDR_WIDTH-1 : ADDR_WIDTH]}: DOUT <= data_reg[1][DATA_WIDTH-1];
                    {1'b0, 1'b1, ADDR[3*ADDR_WIDTH-1 : 2*ADDR_WIDTH]}: DOUT <= data_reg[2][DATA_WIDTH-1];
                    {1'b0, 1'b1, ADDR[4*ADDR_WIDTH-1 : 3*ADDR_WIDTH]}: DOUT <= data_reg[3][DATA_WIDTH-1];
                    {1'b0, 1'b1, ADDR[5*ADDR_WIDTH-1 : 4*ADDR_WIDTH]}: DOUT <= data_reg[4][DATA_WIDTH-1];
                    default : DOUT <= 1'b0;
                endcase
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
                        addr_reg[ADDR_WIDTH-1 : 1] <= {addr_reg[ADDR_WIDTH-2 : 1], DIN};
                    end

                if (addr0_shft_en) 
                    begin 
                        addr_reg[0] <= DIN;
                    end
            end
    end // always

// write/read cycle count & few more things
always @ (posedge CLK, negedge RSTN) 
    begin
        if (!RSTN) 
            begin
                cnt <= 4'h0;
                data_shft_en_1 <= 1'b0;
                wr_stage <= 1'b0;
            end
        else 
            begin
                data_shft_en_1 <= data_shft_en_0;

                if (WR_EN)
                    begin
                        wr_stage <= 1'b1;
                    end
                else if (~data_shft_en_0 & data_shft_en_1) // last cycle of data write
                    begin
                        wr_stage <= 1'b0;
                    end
                
                if ((1'b1 == WR_EN || 1'b1 == RD_EN) && 4'h0 == cnt)
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
