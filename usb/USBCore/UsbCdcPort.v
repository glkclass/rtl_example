
//--------------------------------------------------------------------------------------------------------
// Module  : usb_cdc
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: A USB Full Speed (12Mbps) device, act as a USB CDC device (USB-Serial)
//--------------------------------------------------------------------------------------------------------

module UsbCdcPort #(
    parameter          DEBUG = "FALSE"   // whether to output USB debug info, "TRUE" or "FALSE"
) (
    input  wire        rstn,            // active-low reset, reset when rstn=0 (USB will unplug when reset), normally set to 1
    input  wire        clk,             // 60MHz is required
    // USB signals
    output              usb_dp_pull,    // connect to USB D+ by an 1.5k resistor
    input               usb_dp_i,       // USB D+
    output              usb_dp_o,       // USB D+
    output              usb_dp_t,       // USB D+
    input               usb_dn_i,       // USB D-
    output              usb_dn_o,       // USB D-
    output              usb_dn_t,       // USB D-
    // USB reset output
    output wire        usb_rstn,      // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
    // CDC receive data (host-to-device)
    output wire [ 7:0] rx_data,         // received data byte
    output wire        rx_valid,        // when recv_valid=1 pulses, a data byte is received on recv_data
    // CDC send data (device-to-host)
    input  wire [ 7:0] tx_data,         // data byte to send
    input  wire        tx_valid,        // when device want to send a data byte, set send_valid=1. the data byte will be sent successfully when (send_valid=1 && send_ready=1).
    output wire        tx_ready,        // send_ready handshakes with send_valid. send_ready=1 indicates send-buffer is not full and will accept the byte on send_data. send_ready=0 indicates send-buffer is full and cannot accept a new byte. 
    // debug output info, only for USB developers, can be ignored for normally use
    output wire        debug_en,        // when debug_en=1 pulses, a byte of debug info appears on debug_data
    output wire [ 7:0] debug_data,      // 
    output wire        debug_uart_tx    // debug_uart_tx is the signal after converting {debug_en,debug_data} to UART (format: 115200,8,n,1). If you want to transmit debug info via UART, you can use this signal. If you want to transmit debug info via other custom protocols, please ignore this signal and use {debug_en,debug_data}.
);

//-------------------------------------------------------------------------------------------------------------------------------------
// USB full-speed core
//-------------------------------------------------------------------------------------------------------------------------------------
usbfs_core_top  #(
    .DESCRIPTOR_DEVICE  ( {  //  18 bytes available
        144'h12_01_10_01_02_00_00_20_9A_FB_9A_FB_00_01_01_02_00_01
    } ),
    .DESCRIPTOR_STR1    ( {  //  64 bytes available
        352'h2C_03_67_00_69_00_74_00_68_00_75_00_62_00_2e_00_63_00_6f_00_6d_00_2f_00_57_00_61_00_6e_00_67_00_58_00_75_00_61_00_6e_00_39_00_35_00,  // "github.com/WangXuan95"
        160'h0
    } ),
    .DESCRIPTOR_STR2    ( {  //  64 bytes available
        256'h20_03_46_00_50_00_47_00_41_00_2d_00_55_00_53_00_42_00_2d_00_53_00_65_00_72_00_69_00_61_00_6c_00,                                      // "FPGA-USB-Serial"
        256'h0
    } ),
    .DESCRIPTOR_CONFIG  ( {  // 512 bytes available
        72'h09_02_39_00_02_01_00_80_64,        // configuration descriptor
        72'h09_04_00_00_01_02_02_01_00,        // interface descriptor (communication control class)
        32'h04_24_02_00,                       // functional descriptor (abstract control management)
        40'h05_24_06_00_01,                    // functional descriptor (union)
        56'h07_05_88_03_08_00_FF,              // endpoint descriptor (notify IN)
        72'h09_04_01_00_02_0A_00_00_00,        // interface descriptor (communication data class)
        56'h07_05_81_02_40_00_00,              // endpoint descriptor (data IN)
        56'h07_05_01_02_20_00_00,              // endpoint descriptor (data OUT)
        3640'h0
    } ),
    .EP81_MAXPKTSIZE    ( 10'h20           ),   // Here, I make the maximum packet length actually sent by the in endpoint (0x20) be less than the maximum packet length specified by the endpoint descriptor (0x40), not equal to it. Because the test shows that when the actual sent packet length = the maximum packet length specified by the descriptor, the host will not submit the received data to the software immediately (unknown reason).
    .DEBUG              ( DEBUG            )
) u_usbfs_core (
    .rstn               ( rstn             ),
    .clk                ( clk              ),
    .usb_dp_pull        ( usb_dp_pull      ),
    .usb_dp_i           ( usb_dp_i         ),
    .usb_dp_o           ( usb_dp_o         ),
    .usb_dp_t           ( usb_dp_t         ),
    .usb_dn_i           ( usb_dn_i         ),
    .usb_dn_o           ( usb_dn_o         ),
    .usb_dn_t           ( usb_dn_t         ),
    .usb_rstn           ( usb_rstn         ),
    .sot                (                  ),
    .sof                (                  ),
    .ep00_setup_cmd     (                  ),
    .ep00_resp_idx      (                  ),
    .ep00_resp          ( 8'h0             ),
    .ep81_data          ( tx_data          ),
    .ep81_valid         ( tx_valid         ),
    .ep81_ready         ( tx_ready         ),
    .ep82_data          ( 8'h0             ),
    .ep82_valid         ( 1'b0             ),
    .ep82_ready         (                  ),
    .ep83_data          ( 8'h0             ),
    .ep83_valid         ( 1'b0             ),
    .ep83_ready         (                  ),
    .ep84_data          ( 8'h0             ),
    .ep84_valid         ( 1'b0             ),
    .ep84_ready         (                  ),
    .ep01_data          ( rx_data          ),
    .ep01_valid         ( rx_valid         ),
    .ep02_data          (                  ),
    .ep02_valid         (                  ),
    .ep03_data          (                  ),
    .ep03_valid         (                  ),
    .ep04_data          (                  ),
    .ep04_valid         (                  ),
    .debug_en           ( debug_en         ),
    .debug_data         ( debug_data       ),
    .debug_uart_tx      ( debug_uart_tx    )
);


endmodule
