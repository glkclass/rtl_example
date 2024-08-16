//--------------------------------------------------------------------------------------------------------
// Module   : proxy_board_tb
// Type     : tb
// Standard : SystemVerilog
//--------------------------------------------------------------------------------------------------------

import dutb_param_pkg::*;
import dutb_util_pkg::*;


// ============================================================================================================================
module proxy_board_tb
    (

        // Proxy board master clock 
        input   logic                       master_clock,

        // Proxy board SPI
        input   logic                       sspi_sck,
        input   logic                       sspi_cs,
        input   logic                       sspi_sdi,
        
        // Proxy board Frame
        output  logic                       pixel_clock     = 1'b0,
        output  logic                       frame_valid     = 1'b0,
        output  logic                       line_valid      = 1'b0,
        output  logic [15:0]                data            = 16'h3344,
        input   logic                       frame_trigger
    );

    localparam
        N_LINE          =   480,
        N_COL           =   640,
        H_SYNC_LENGTH   =   25,
        V_SYNC_LENGTH   =   689;

    int 
        pixel_cnt   =   0,
        line_cnt    =   0,
        frame_cnt   =   -1,
        data_cnt    =   0;


    clk_gen #(.FREQ(0.0096)) u_clk_27MHz(.clk (pixel_clock));

    initial
        begin
            #20us            
            @(negedge pixel_clock);
            {frame_valid, line_valid}     = {LOW, LOW};
            repeat (240)
                begin
                    frame_cnt   +=  1;
                    line_cnt    =   0;
                    repeat(V_SYNC_LENGTH) @(negedge pixel_clock); 
                    frame_valid     =   HIGH;
                    pixel_cnt       =   0;
                    @(negedge pixel_clock); 
                    line_valid      = HIGH;
                    data_cnt        =   0;
                    data            =   word_crc(data_cnt, 16'h537A);
                    repeat (N_COL)
                        begin
                            @(negedge pixel_clock);
                            pixel_cnt           =   pixel_cnt + 1;
                            data_cnt            += 1;
                            data                =   word_crc(data_cnt, 16'h537A);
                        end
                    line_valid                  = LOW;

                    repeat(N_LINE-1)
                        begin
                            line_cnt            += 1;
                            repeat(H_SYNC_LENGTH) @(negedge pixel_clock); 
                            line_valid          =   HIGH;
                            repeat (N_COL)
                                begin
                                    @(negedge pixel_clock); 
                                    pixel_cnt   =   pixel_cnt + 1;
                                    data_cnt    += 1;
                                    data        =   word_crc(data_cnt, 16'h537A);
                                end
                            line_valid          =   LOW;
                        end
                    frame_valid                 = LOW;
                end
        end

endmodule



