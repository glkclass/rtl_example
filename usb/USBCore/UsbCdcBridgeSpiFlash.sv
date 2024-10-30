//-----------------------------------------------------------------------------------------------------------------------------
// Module   : UsbCdcBridgeSpiFlash
// Type     : synthesizable, FPGA top
// Standard : SystemVerilog
//-----------------------------------------------------------------------------------------------------------------------------


// ============================================================================================================================
module UsbCdcBridgeSpiFlash (
    // Clock definition ---------------------------------------
    input   logic                           rst_n,
    input   logic                           clk_60MHz,
    // End ----------------------------------------------------

    // SPI User Flash -----------------------------------------
    output  logic                           spi_sck,
                                            spi_cs,
    output  reg                             spi_sio_0,
    input   logic                           spi_sio_1,
    // End ----------------------------------------------------

    // USB 1.1 interface ------------------------------------------
    // USB signals
    output                                  usb_dp_pull,    // connect to USB D+ by an 1.5k resistor
    input                                   usb_dp_i,       // USB D+
    output                                  usb_dp_o,       // USB D+
    output                                  usb_dp_t,       // USB D+
    input                                   usb_dn_i,       // USB D-
    output                                  usb_dn_o,       // USB D-
    output                                  usb_dn_t        // USB D-
    // End ----------------------------------------------------
);
// ============================================================================================================================


// params
    localparam
        DATA_WIDTH          =   8;

// logic
    logic    
                            rx_valid,
                            tx_valid,
                            tx_ready;

    // usb cdc
    logic   [DATA_WIDTH - 1     :   0]          
                            usb_rx_data,
                            usb_tx_data;
    logic
                            usb_rx_valid,
                            usb_tx_valid,
                            usb_tx_ready;


    // fifo
    logic
                            rx_fifo_full,
                            rx_fifo_rd_en,
                            rx_fifo_empty,
                            rx_fifo_valid,

                            tx_fifo_full,
                            tx_fifo_empty,
                            tx_fifo_valid;


    logic   [DATA_WIDTH - 1     :   0]
                            rx_fifo_data,
                            tx_fifo_data;

    logic   [10 - 1             :   0]
                            rx_fifo_size,
                            tx_fifo_size;




// ============================================================================================================================

    //
        // send / recieve byte via USB CDC
        `ifndef DUTB
            UsbCdcPort usb_cdc_port (
        `else
            usb_cdc_tb u_usb_cdc (
        `endif            
                .rstn                       (rst_n),
                .clk                        (clk_60MHz),
                
                // USB reset output
                .usb_rstn                   (led),                              // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
                
                // CDC receive data (host-to-device)
                .rx_data                    (usb_rx_data),                      // received data byte
                .rx_valid                   (usb_rx_valid),                     // received data byte valid
                
                // CDC send data (device-to-host)
                .tx_data                    (usb_tx_data),                      // data to send
                .tx_valid                   (usb_tx_valid),                     // data to send handshake
                .tx_ready                   (usb_tx_ready),                     // data to send handshake

                .usb_dp_pull                (usb_dp_pull),
                .usb_dp_i                   (usb_dp_i),
                .usb_dp_o                   (usb_dp_o),
                .usb_dp_t                   (usb_dp_t),
                .usb_dn_i                   (usb_dn_i),
                .usb_dn_o                   (usb_dn_o),
                .usb_dn_t                   (usb_dn_t)
            );

    //
        // USB Rx buffer: USB -> FIFO -> BRIDGE
        UsbCdcFifo usb_cdc_fifo_rx (
            .clk                            (clk_60MHz),                // input wire clk
            .srst                           (1'b0),                     // input wire srst
            .data_count                     (rx_fifo_size),             // output wire [9 : 0] data_count

            // usb -> fifo
            .din                            (usb_rx_data),              // input wire [7 : 0] din
            .wr_en                          (usb_rx_valid),             // input wire wr_en
            .full                           (rx_fifo_full),             // output wire full

            // fifo -> bridge
            .rd_en                          (rx_fifo_rd_en),            // input wire rd_en
            .dout                           (rx_fifo_data),             // output wire [7 : 0] dout
            .empty                          (rx_fifo_empty),            // output wire empty
            .valid                          (rx_fifo_valid)             // output wire valid
        );

    //
        // USB Tx buffer: BRIDGE -> FIFO -> USB
        UsbCdcFifo usb_cdc_fifo_tx (
            .clk                            (clk_60MHz),                // input wire clk
            .srst                           (1'b0),                     // input wire srst
            .data_count                     (tx_fifo_size),             // output wire [9 : 0] data_count

            // bridge -> fifo
            .din                            (tx_fifo_data),             // input wire [7 : 0] din
            .wr_en                          (tx_fifo_valid),            // input wire wr_en
            .full                           (tx_fifo_full),             // output wire full

            // fifo -> usb
            .rd_en                          (usb_tx_ready),             // input wire rd_en
            .dout                           (usb_tx_data),              // output wire [7 : 0] dout
            .empty                          (tx_fifo_empty),            // output wire empty
            .valid                          (usb_tx_valid)              // output wire valid
        );

    //
        // read out and execute commands recieved via USB
        SpiFlashFace spi_flash_face (
            .clk                            (clk_60MHz),
            .rst_n                          (rst_n),

            // fifo -> bridge
            .rx_fifo_size                   (rx_fifo_size),
            .rx_fifo_data                   (rx_fifo_data),
            .rx_fifo_rd_en                  (rx_fifo_rd_en),
            .rx_fifo_valid                  (rx_fifo_valid),
    
            // bridge -> fifo
            .tx_fifo_size                   (tx_fifo_size),
            .tx_fifo_data                   (tx_fifo_data),
            .tx_fifo_valid                  (tx_fifo_valid),
            .tx_fifo_full                   (tx_fifo_full),


            // spi flash if
            .spi_sck                        (spi_sck),
            .spi_cs                         (spi_cs),
            .spi_sio_0                      (spi_sio_0),
            .spi_sio_1                      (spi_sio_1)
        );


endmodule
// ============================================================================================================================