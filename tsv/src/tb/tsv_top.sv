// `include "dutb_param_pkg.sv"
import dutb_param_pkg::*;
import dutb_util_pkg::*;

// ============================================================================================================================
module tsv_top ();
    logic                               clk_27MHz;


// ============================================================================================================================


    clk_gen #(.FREQ(0.027)) u_clk_27MHz(.clk (clk_27MHz));
    
    proxy_board_tb u_proxy_board_tb
        (
        .master_clock       (LOW),

        .sspi_sck           (LOW),
        .sspi_cs            (LOW),
        .sspi_sdi           (LOW),
        
        .pixel_clock        (pixel_clock),
        .frame_valid        (frame_valid),
        .line_valid         (line_valid),
        .data               (data),
        .frame_trigger      (frame_trigger)
            );


    top dut(
        .board_clk_27(clk_27MHz),
        
        // leds
        .led_green(),
        .led_yellow()
        
        // // 1v8 reset, supposed to be input, but set to output for debugging purposes
        // output reset_1v8_n,

        // // DDR3 interface, commented out until needed
        // output [14:0]ddr3_addr,
        // output [2:0]ddr3_ba,
        // output ddr3_cas_n,
        // output [0:0]ddr3_ck_n,
        // output [0:0]ddr3_ck_p,
        // output [0:0]ddr3_cke,
        // output [1:0]ddr3_dm,
        // inout [15:0]ddr3_dq,
        // inout [1:0]ddr3_dqs_n,
        // inout [1:0]ddr3_dqs_p,
        // output [0:0]ddr3_odt,
        // output ddr3_ras_n,
        // output ddr3_reset_n,
        // output ddr3_we_n,
      
        // // sccb interface
        // inout sio_c,
        // inout sio_d,

        // // i2c interfaces
        // inout scl1,
        // inout sda1,
        // inout scl2,
        // inout sda2,

        // // MIPI CSI-2 output
        // // single-lane interface
        // output mipi_phy_clk_hs_p,
        // output mipi_phy_clk_hs_n,
        // output mipi_phy_clk_lp_p,
        // output mipi_phy_clk_lp_n,
        // output mipi_phy_data_hs_p,
        // output mipi_phy_data_hs_n,
        // output mipi_phy_data_lp_p,
        // output mipi_phy_data_lp_n,
        // // out of spec clock unused clock
        // output mipi_phy_clk_hs_p_outofspec,
        // output mipi_phy_clk_hs_n_outofspec,

        // // PAL DAC outputs
        // output [15:0] pal_dac_p,
        // inout  pal_dac_hsync,
        // inout  pal_dac_vsync,
        // output pal_dac_clk,

        // // sensor data interface
        // output sensor_master_clk,
        // input  sensor_pixel_clk,
        // input  sensor_hsync,
        // input  sensor_vsync,
        // input [15:0] sensor_data,

        // output sensor_trigger,

        // // sensor configuration interface
        // output sensor_sck,
        // output sensor_cs_n,
        // output sensor_mosi,
        
        // // shutter controls
        // output shutter_ph,
        // output shutter_en,
        // output shutter_mode,

        // // debug gpio outputs
        // output gpio0,
        // inout gpio1,
        // inout gpio2,
        // output gpio3,
        // output gpio4,
        // //output gpio5, // gpio 5/6 taken by slave i2c interface
        // //output gpio6,
        
        // // config flash
        // inout cflash_spi_io0,
        // inout cflash_spi_io1,
        // inout cflash_spi_io2,
        // inout cflash_spi_io3,
        // inout cflash_spi_ss,


        // // coeff flash
        // inout   coeff_flash_spi_io0,
        // inout   coeff_flash_spi_io1,
        // inout   coeff_flash_spi_io2,
        // inout   coeff_flash_spi_io3,
        // inout   coeff_flash_spi_ss,
        // inout   coeff_flash_spi_sck,
        // output  coeff_flash_spi_reset_n,
        
        // // uart
        // output uart_tx,
        // input uart_rx,

        // // can bus
        // input can_rx,
        // output can_tx,

        // // control inputs
        // input pwm,
        // input s_bus,

        // // XADC inputs
        // input adc_v_p,
        // input adc_v_n
    );





// ============================================================================================================================
    initial
        begin
            $timeformat(-9, 3, "ns", 8);
            timeout_sim(1ms, 100);
        end


    initial 
        begin
            $dumpfile("tsv_top_waveform.vcd"); // Specify the name of the VCD file
            $dumpvars(0, tsv_top);  // Trace signals in top_module
        end

endmodule
// ============================================================================================================================




























