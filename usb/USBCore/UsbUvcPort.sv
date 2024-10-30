
//--------------------------------------------------------------------------------------------------------
// Module  : UsbUvcPort
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: A USB Full Speed (12Mbps) device, acts as a USB UVC camera
//--------------------------------------------------------------------------------------------------------



module UsbUvcPort #(
    parameter
        FRAME_W    = 640,       // video-frame width  in pixels, must be an even number
        FRAME_H    = 480,       // video-frame height in pixels, must be an even number
        DEBUG      = "FALSE"    // whether to output USB debug info, "TRUE" or "FALSE"
) (
    input  wire         rstn,               //  active-low reset, reset when rstn=0 (USB will unplug when reset), normally set to 1
    input  wire         clk_60MHz,          //  60MHz is required
    
    // USB reset output
    output wire         usb_rstn,           //  1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))

    // USB signals
    output              usb_dp_pull,    // connect to USB D+ by an 1.5k resistor
    input               usb_dp_i,       // USB D+
    output              usb_dp_o,       // USB D+
    output              usb_dp_t,       // USB D+
    input               usb_dn_i,       // USB D-
    output              usb_dn_o,       // USB D-
    output              usb_dn_t,       // USB D-
    

    // video frame fetch interface
    output  wire        uvc_ready,          //  uvc_ready=1 -> usb core is ready to accept vf_data
    output  reg         vf_sof,             //  vf_sof=1 indicates start of video frame
    input   wire [7:0]  vf_data,            //  a byte of video data (8-bit pixel or low/high part of 16-bit pixel )
    input   wire        vf_valid,           //  vf_valid=1 -> vf_data is valid
    
    // debug output info, only for USB developers, can be ignored for normally use
    output  wire        debug_en,           // when debug_en=1 pulses, a byte of debug info appears on debug_data
    output  wire [ 7:0] debug_data,         // 
    output  wire        debug_uart_tx       // debug_uart_tx is the signal after converting {debug_en,debug_data} to UART (format: 115200,8,n,1). If you want to transmit debug info via UART, you can use this signal. If you want to transmit debug info via other custom protocols, please ignore this signal and use {debug_en,debug_data}.
);


function  [15:0] toLittleEndian_2byte;
    input [15:0] value;
    begin
        toLittleEndian_2byte = {value[7:0], value[15:8]};
    end
endfunction


function  [31:0] toLittleEndian_4byte;
    input [31:0] value;
    begin
        toLittleEndian_4byte = {value[7:0], value[15:8], value[23:16], value[31:24]};
    end
endfunction



localparam              W_WIDTH                     = FRAME_W;                                      //  video-frame width in pixels
localparam              W_HEIGHT                    = FRAME_H;                                      //  video-frame height in pixels
localparam              FRAME_PIXEL_COUNT           = W_HEIGHT * W_WIDTH;
localparam              DW_MAX_VIDEO_FRAMESIZE      = FRAME_PIXEL_COUNT * 2;                        //  2 bytes for each pixel
localparam              MAX_PACKET_SIZE             = 802;                                          //  USB-packet = 2 byte header + PayloadSize bytes of pixel datas (should be <= 1023 bytes)
localparam              FRAME_INTERVAL_MS           = 1000;                                         //  video-frame interval (unit: 1ms)
localparam              DW_FRAME_INTERVAL           = FRAME_INTERVAL_MS * 10000;                    //  video-frame interval (unit: 100ns)
localparam  [7:0]       HLE                         = 8'h2;                                         //  HLE (header length)
    



//-------------------------------------------------------------------------------------------------------------------------------------
// USB-packet generation for video transmitting
//-------------------------------------------------------------------------------------------------------------------------------------

reg                 packet_req          =   1'b0;                                                   //  USB packet transmitt flag
reg                 fid                 =   1'b0;                                                   //  toggle when each video-frame transmit done
reg     [9:0]       packet_bcnt         =   10'h0;                                                  //  byte count in one USB-packet (include packet header bytes).
reg     [19:0]      vframe_bcnt         =   20'h0;                                                  //  byte count in one video frame
    
// USB packet count in one video frame. May take different values due to different frame sizes (depends on video data availability during USB packet transmitting)
// reg     [19:0]      packet_cnt          =   20'h0;                                              


// USB core if
wire                usb_core_sof;                                                                   // this is a start of USB-frame (every 1 ms)
wire                usb_core_ready;
wire                usb_core_valid;
wire    [7:0]       usb_core_data;



wire                packet_header;
wire                usb_packet_last_byte;
wire                vframe_last_byte;

assign              packet_header               =   (packet_bcnt < 10'h2) ? 1'b1 : 1'b0;                            //  USB packet header is transmitting
assign              vframe_transmit_active      =   (DW_MAX_VIDEO_FRAMESIZE > vframe_bcnt) ? 1'b1 : 1'b0;           //  Video frame is transmitting
assign              vframe_last_byte            =   ((DW_MAX_VIDEO_FRAMESIZE - 1) == vframe_bcnt) ? 1'b1 : 1'b0;    //  Last byte of video frame is transmitting
assign              usb_max_packet_last_byte    =   ((MAX_PACKET_SIZE - 1) == packet_bcnt) ? 1'b1 : 1'b0;           //  Last byte of usb packet (of max size)


assign              usb_core_data               =   (packet_bcnt == 0 ) ? HLE :                                 // HLE (header length) = 2
                                                    (packet_bcnt == 1 ) ? {7'b1000000, fid} :                   // BFH[0]  
                                                    vf_data;                                                    // video frame data

assign              usb_core_valid              =   packet_header | (packet_req & vf_valid);                    //  
assign              uvc_ready                   =   usb_core_ready & packet_req & (~packet_header);             //




always @ (posedge clk_60MHz or negedge usb_rstn)
    if (~usb_rstn) 
        begin
            packet_req      <=  1'b0;
            packet_bcnt     <=  {10{1'b1}};
            vframe_bcnt     <=  {20{1'b1}};
            fid             <=  1'b0;
            vf_sof          <=  1'b0;
        end 
    else 
        begin

            if (usb_core_sof)   //  start of USB frame (once per 1ms)
                begin

                    packet_bcnt     <=  32'h0;
                    packet_req      <=  1'b1;

                    if (1'b0 == vframe_transmit_active)            //  no active vframe transmitt
                        begin
                            vframe_bcnt     <=  {20{1'b0}};         //  reset frame byte counter
                            fid             <=  ~fid;               //  toggle even/odd frame flag
                            vf_sof          <=  1'b1;               //  'start new video frame' impulse
                        end
                end 
            else
                begin     
                    vf_sof              <=  1'b0;
                    
                    if (usb_core_ready)
                        begin
                            if (packet_req & packet_header)
                                begin
                                    packet_bcnt <= packet_bcnt + 10'h1;  //  packet header generated internaly and independently from  external valid handshake
                                end
                            else 
                                begin
                                    if (vf_valid) 
                                        begin
                                            if (packet_req) 
                                                begin
                                                    packet_bcnt <= packet_bcnt + 10'h1; 
                                                    vframe_bcnt <= vframe_bcnt + 20'h1;

                                                    if ( (1'b1 == vframe_last_byte) || 
                                                        (1'b1 == usb_max_packet_last_byte) )    //  this check is duplicated inside usb core (usbfs_transaction). So can be skiped here.
                                                        begin
                                                            packet_req      <=  1'b0;           //  finish USB packet (once per USB frame) when last byte of video frame sent or max USB packet size achieved
                                                        end
                                                end
                                        end 
                                    else 
                                        begin
                                            packet_req      <=  1'b0;   //  finish USB packet (once per USB frame) when no data to send
                                        end
                                end
                        end
                end
        end





//-------------------------------------------------------------------------------------------------------------------------------------
// endpoint 00 (control endpoint) command response : UVC Video Probe and Commit Controls
//-------------------------------------------------------------------------------------------------------------------------------------
localparam [34*8-1:0] UVC_PROBE_COMMIT = {
    16'h00_00,                                                      // bmHint
     8'h01,                                                         // bFormatIndex
     8'h01,                                                         // bFrameIndex
    toLittleEndian_4byte(DW_FRAME_INTERVAL),                        // dwFrameInterval
    16'h00_00,                                                      // wKeyFrameRate    : ignored by uncompressed video
    16'h00_00,                                                      // wPFrameRate      : ignored by uncompressed video
    16'h00_00,                                                      // wCompQuality     : ignored by uncompressed video
    16'h00_00,                                                      // wCompWindowSize  : ignored by uncompressed video
    16'h01_00,                                                      // wDelay (ms)
    toLittleEndian_4byte(DW_MAX_VIDEO_FRAMESIZE),                   // dwMaxVideoFrameSize
    toLittleEndian_4byte(MAX_PACKET_SIZE),                          // dwMaxPayloadTransferSize
    32'h80_8D_5B_00,                                                // dwClockFrequency
     8'h03,                                                         // bmFramingInfo
     8'h00,                                                         // bPreferedVersion
     8'h00,                                                         // bMinVersion
     8'h00                                                          // bMaxVersion
};

wire [63:0] ep00_setup_cmd;
wire [ 8:0] ep00_resp_idx;
reg  [ 7:0] ep00_resp;

always @ (posedge clk_60MHz)
    if ((ep00_setup_cmd[7:0] == 8'hA1) && (ep00_setup_cmd[47:16] == 32'h0001_0100))
        ep00_resp <= UVC_PROBE_COMMIT[ (34 - 1 - ep00_resp_idx) * 8 +: 8 ];
    else
        ep00_resp <= 8'h0;




//-------------------------------------------------------------------------------------------------------------------------------------
// USB full-speed core
//-------------------------------------------------------------------------------------------------------------------------------------
usbfs_core_top  #(
    .DESCRIPTOR_DEVICE  ( {  //  18 bytes available
        144'h12_01_10_01_EF_02_01_20_9A_FB_9A_FB_00_01_01_02_00_01
    } ),
    .DESCRIPTOR_STR1    ( {  //  64 bytes available
        352'h2C_03_67_00_69_00_74_00_68_00_75_00_62_00_2e_00_63_00_6f_00_6d_00_2f_00_57_00_61_00_6e_00_67_00_58_00_75_00_61_00_6e_00_39_00_35_00,  // "github.com/WangXuan95"
        160'h0
    } ),
    .DESCRIPTOR_STR2    ( {  //  64 bytes available
        336'h2A_03_46_00_50_00_47_00_41_00_2d_00_55_00_53_00_42_00_2d_00_76_00_69_00_64_00_65_00_6f_00_2d_00_69_00_6e_00_70_00_75_00_74_00,        // "FPGA-USB-video-input"
        176'h0
    } ),
    .DESCRIPTOR_CONFIG  ( {  // 512 bytes available
         72'h09_02_9A_00_02_01_00_80_64,                                                            // configuration descriptor, 2 interfaces
         64'h08_0B_00_02_0E_03_00_02,                                                               // interface association descriptor, video interface collection
         72'h09_04_00_00_00_0E_01_00_02,                                                            // interface descriptor, video, 1 endpoints
        104'h0D_24_01_10_01_20_00_80_8D_5B_00_01_01,                                                // video control interface header descriptor
         80'h0A_24_02_01_02_02_00_00_00_00,                                                         // video control input terminal descriptor
         72'h09_24_03_02_01_01_00_01_00,                                                            // video control output terminal descriptor
         72'h09_04_01_00_00_0E_02_00_00,                                                            // interface descriptor, video, 0 endpoints
        112'h0E_24_01_01_47_00_81_00_02_00_00_00_01_00,                                             // video streaming interface input header descriptor
        216'h1B_24_04_01_01_59_55_59_32_00_00_10_00_80_00_00_AA_00_38_9B_71_10_01_00_00_00_00,      // video streaming uncompressed video format descriptor
         40'h1E_24_05_01_02, toLittleEndian_2byte(W_WIDTH), toLittleEndian_2byte(W_HEIGHT), 96'h00_00_01_00_00_00_10_00_00_00_01_00, toLittleEndian_4byte(DW_FRAME_INTERVAL), 8'h01, toLittleEndian_4byte(DW_FRAME_INTERVAL),  // video streaming uncompressed video frame descriptor
         72'h09_04_01_01_01_0E_02_00_00,                                                            // interface descriptor, video, 1 endpoints
         32'h07_05_81_01, toLittleEndian_2byte({6'h0, MAX_PACKET_SIZE}), 8'h01,                     // endpoint descriptor, 81
        2864'h0
    } ),
    .EP81_MAXPKTSIZE    ( MAX_PACKET_SIZE   ),
    .EP81_ISOCHRONOUS   ( 1                 ),
    .DEBUG              ( DEBUG             )
) usbfs_core_i (    
    .rstn               ( rstn              ),
    .clk                ( clk_60MHz         ),
    .usb_dp_pull        ( usb_dp_pull       ),
    .usb_dp_i           ( usb_dp_i          ),
    .usb_dp_o           ( usb_dp_o          ),
    .usb_dp_t           ( usb_dp_t          ),
    .usb_dn_i           ( usb_dn_i          ),
    .usb_dn_o           ( usb_dn_o          ),
    .usb_dn_t           ( usb_dn_t          ),
    .usb_rstn           ( usb_rstn          ),
    .sot                (                   ),
    .sof                ( usb_core_sof      ),
    .ep00_setup_cmd     ( ep00_setup_cmd    ),
    .ep00_resp_idx      ( ep00_resp_idx     ),
    .ep00_resp          ( ep00_resp         ),
    .ep81_data          ( usb_core_data     ),
    .ep81_valid         ( usb_core_valid    ),
    .ep81_ready         ( usb_core_ready    ),
    .ep82_data          ( 8'h0              ),
    .ep82_valid         ( 1'b0              ),
    .ep82_ready         (                   ),
    .ep83_data          ( 8'h0              ),
    .ep83_valid         ( 1'b0              ),
    .ep83_ready         (                   ),
    .ep84_data          ( 8'h0              ),
    .ep84_valid         ( 1'b0              ),
    .ep84_ready         (                   ),
    .ep01_data          (                   ),
    .ep01_valid         (                   ),
    .ep02_data          (                   ),
    .ep02_valid         (                   ),
    .ep03_data          (                   ),
    .ep03_valid         (                   ),
    .ep04_data          (                   ),
    .ep04_valid         (                   ),
    .debug_en           ( debug_en          ),
    .debug_data         ( debug_data        ),
    .debug_uart_tx      ( debug_uart_tx     )
);  



endmodule
