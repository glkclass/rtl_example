module top(
    input board_clk_27,
    
    // leds
    output led_green,
    output led_yellow,
    
    // 1v8 reset, supposed to be input, but set to output for debugging purposes
    output reset_1v8_n,

    // DDR3 interface, commented out until needed
    output [14:0]ddr3_addr,
    output [2:0]ddr3_ba,
    output ddr3_cas_n,
    output [0:0]ddr3_ck_n,
    output [0:0]ddr3_ck_p,
    output [0:0]ddr3_cke,
    output [1:0]ddr3_dm,
    inout [15:0]ddr3_dq,
    inout [1:0]ddr3_dqs_n,
    inout [1:0]ddr3_dqs_p,
    output [0:0]ddr3_odt,
    output ddr3_ras_n,
    output ddr3_reset_n,
    output ddr3_we_n,
  
    // sccb interface
    inout sio_c,
    inout sio_d,

    // i2c interfaces
    inout scl1,
    inout sda1,
    inout scl2,
    inout sda2,

    // MIPI CSI-2 output
    // single-lane interface
    output mipi_phy_clk_hs_p,
    output mipi_phy_clk_hs_n,
    output mipi_phy_clk_lp_p,
    output mipi_phy_clk_lp_n,
    output mipi_phy_data_hs_p,
    output mipi_phy_data_hs_n,
    output mipi_phy_data_lp_p,
    output mipi_phy_data_lp_n,
    // out of spec clock unused clock
    output mipi_phy_clk_hs_p_outofspec,
    output mipi_phy_clk_hs_n_outofspec,

    // PAL DAC outputs
    output [15:0] pal_dac_p,
    inout  pal_dac_hsync,
    inout  pal_dac_vsync,
    output pal_dac_clk,

    // sensor data interface
    output sensor_master_clk,
    input  sensor_pixel_clk,
    input  sensor_hsync,
    input  sensor_vsync,
    input [15:0] sensor_data,

    output sensor_trigger,

    // sensor configuration interface
    output sensor_sck,
    output sensor_cs_n,
    output sensor_mosi,
    
    // shutter controls
    output shutter_ph,
    output shutter_en,
    output shutter_mode,

    // debug gpio outputs
    inout gpio0,
    inout gpio1,
    inout gpio2,
    inout gpio3,
    inout gpio4,
    inout gpio5,
    inout gpio6,
    
    // config flash
    inout cflash_spi_io0,
    inout cflash_spi_io1,
    inout cflash_spi_io2,
    inout cflash_spi_io3,
    inout cflash_spi_ss,


    // coeff flash
    inout   coeff_flash_spi_io0,
    inout   coeff_flash_spi_io1,
    inout   coeff_flash_spi_io2,
    inout   coeff_flash_spi_io3,
    output  coeff_flash_spi_ss,
    output  coeff_flash_spi_sck,
    output  coeff_flash_spi_reset_n,
    
    // uart
    output uart_tx,
    input uart_rx,

    // can bus
    input can_rx,
    output can_tx,

    // control inputs
    input pwm,
    input s_bus,

    // XADC inputs
    input adc_v_p,
    input adc_v_n
);

// image pipeline switches: image_pipeline_setup[23:0] = {PAL_FLAGS[7:0], MIPI_CSI_FLAGS[7:0], GENERAL_FLAGS[7:0]}
// Should be aligned with appropriate flag offsets in MicroBlaze Core c-env.
localparam  GENERAL_FLAGS_BASE_OFFS                     =   0;

// general switches
localparam  GENERAL_USB_UVC_CDC_SWITCH_OFFS             =   GENERAL_FLAGS_BASE_OFFS + 1;    //  1'b0 - USB UVC, 1'b1 - USB CDC


wire     [24 - 1    :    0]     image_pipeline_setup;


`define USB_DP_PULL     gpio0
`define USB_DP          gpio1
`define USB_DN          gpio2

wire    usb_uvc_dp_i, usb_uvc_dp_o, usb_uvc_dp_t, usb_uvc_dn_i, usb_uvc_dn_o, usb_uvc_dn_t, usb_uvc_dp_pull;
wire    usb_cdc_dp_i, usb_cdc_dp_o, usb_cdc_dp_t, usb_cdc_dn_i, usb_cdc_dn_o, usb_cdc_dn_t, usb_cdc_dp_pull;
wire    usb_dp_t, usb_dn_t, usb_dp_o, usb_dn_o;
wire    usb_reset_n;

assign  usb_uvc_dp_i    =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? 1'b0 : `USB_DP;
assign  usb_cdc_dp_i    =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? `USB_DP : 1'b0;
assign  usb_dp_t        =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? usb_cdc_dp_t : usb_uvc_dp_t;
assign  usb_dp_o        =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? usb_cdc_dp_o : usb_uvc_dp_o;
assign `USB_DP          =   usb_dp_t  ? usb_dp_o : 1'bZ;

assign  usb_uvc_dn_i    =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? 1'b0 : `USB_DN;
assign  usb_cdc_dn_i    =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? `USB_DN : 1'b0;
assign  usb_dn_t        =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? usb_cdc_dn_t : usb_uvc_dn_t;
assign  usb_dn_o        =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? usb_cdc_dn_o : usb_uvc_dn_o;
assign `USB_DN          =   usb_dn_t  ? usb_dn_o : 1'bZ;

assign `USB_DP_PULL     =   image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS] ? usb_cdc_dp_pull : usb_uvc_dp_pull;


UsbResetBridge usb_reset_bridge(.rst_n(locked), .clk(axi_clk), .usb_working_mode(image_pipeline_setup[GENERAL_USB_UVC_CDC_SWITCH_OFFS]), .usb_reset_n(usb_reset_n));


// Read frame from DDR-3 memory and stream to UVC (using 3 GPIO pins)
UsbUvcStreamer #(
    .FRAME_W                        (640),              // video-frame width  in pixels, must be a even number
    .FRAME_H                        (480)               // video-frame height in pixels, must be a even number
)
usb_uvc_streamer (
    .rst_n                          (locked & usb_reset_n),
    .clk_60MHz                      (clk_60MHz),
    .axi_clk                        (axi_clk),

    .frame_buffer_addr              (uvc_streamer_buffer_addr),
    .next_frame_buffer_request      (uvc_streamer_change_buffer_req),

    // AXI bus
    .rready                         (uvc_axi_rready),
    .rdata                          (uvc_axi_rdata),
    .rvalid                         (uvc_axi_rvalid),

    .arready                        (uvc_axi_arready),
    .araddr                         (uvc_axi_araddr),
    .arvalid                        (uvc_axi_arvalid),
    .arlen                          (uvc_axi_arlen),
    .arsize                         (uvc_axi_arsize),
    .arburst                        (uvc_axi_arburst),

    // USB interface
    .usb_dp_i                       (usb_uvc_dp_i),
    .usb_dp_o                       (usb_uvc_dp_o),
    .usb_dp_t                       (usb_uvc_dp_t),
    .usb_dn_i                       (usb_uvc_dn_i),
    .usb_dn_o                       (usb_uvc_dn_o),
    .usb_dn_t                       (usb_uvc_dn_t),
    .usb_dp_pull                    (usb_uvc_dp_pull)
);

// Bridge between USB CDC port and SPI Flash
UsbCdcBridgeSpiFlash usb_cdc_bridge_spi_flash (
    .rst_n                          (locked & usb_reset_n),
    .clk_60MHz                      (clk_60MHz),

    // SPI Flash
    .spi_sck                        (usb_cdc_bridge_spi_sck),
    .spi_cs                         (usb_cdc_bridge_spi_cs),
    .spi_sio_0                      (usb_cdc_bridge_spi_sio_0),
    .spi_sio_1                      (usb_cdc_bridge_spi_sio_1),

    // USB interface
    .usb_dp_i                       (usb_cdc_dp_i),
    .usb_dp_o                       (usb_cdc_dp_o),
    .usb_dp_t                       (usb_cdc_dp_t),
    .usb_dn_i                       (usb_cdc_dn_i),
    .usb_dn_o                       (usb_cdc_dn_o),
    .usb_dn_t                       (usb_cdc_dn_t),
    .usb_dp_pull                    (usb_cdc_dp_pull)
);


endmodule


