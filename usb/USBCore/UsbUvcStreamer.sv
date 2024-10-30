//--------------------------------------------------------------------------------------------------------
// Module   : UsbUvcStreamer
// Type     : synthesizable, FPGA top
// Standard : SystemVerilog
//--------------------------------------------------------------------------------------------------------

// ============================================================================================================================
module UsbUvcStreamer 
    #(
        parameter       
            FRAME_W                             = 640,      // video-frame width  in pixels, must be an even number
            FRAME_H                             = 480       // video-frame height in pixels, must be an even number
    )
    (
        input                                   rst_n,
        input                                   clk_60MHz,      // 60 MHz clock for USB Core
        input                                   axi_clk,        // 150 MHZ

        input   [32 - 1     :   0]              frame_buffer_addr,                  //  frame buffer
        output                      reg         next_frame_buffer_request,          //  request for new frame buffer to read out

        // AXI bus
        output                      reg         rready,
        input   [64 - 1     :   0]              rdata,
        input                                   rvalid,

        input                                   arready,
        output  [32 - 1     :   0]              araddr,
        output  [8 - 1      :   0]              arlen,
        output  [3 - 1      :   0]              arsize,
        output  [2 - 1      :   0]              arburst,
        output                                  arvalid,

        // USB signals
        output                                  usb_dp_pull,    // connect to USB D+ by an 1.5k resistor
        input                                   usb_dp_i,       // USB D+
        output                                  usb_dp_o,       // USB D+
        output                                  usb_dp_t,       // USB D+
        input                                   usb_dn_i,       // USB D-
        output                                  usb_dn_o,       // USB D-
        output                                  usb_dn_t       // USB D-
    );
// ============================================================================================================================

// params
    localparam                          BYTE_WIDTH                          =   8;                  //  byte width
    localparam                          PIXEL_WIDTH                         =   2 * BYTE_WIDTH;     //  pixel width
    localparam                          N_ROWS                              =   640;                //  size of frame line
    localparam                          N_LINES                             =   480;                //  snumber of frame lines
    localparam                          N_PIXEL_FRAME                       =   N_LINES*N_ROWS;     //  size of frame to transmit (16-bit pixels): 640*480 = 307200
    localparam                          LINE_STRIDE                         =   11'h000;            //  720 (PAL frame) pixels * 2 bytes = 1440 bytes => 2048 bytes stride

    localparam      [3 - 1     : 0]     IDLE_ST                             =   3'h0;
    localparam      [3 - 1     : 0]     WRITE_LINE_ADDR_TXN_ST              =   3'h1;
    localparam      [3 - 1     : 0]     WAIT_FOR_DATA_BURST_FINISHED_ST     =   3'h2;
    localparam      [3 - 1     : 0]     NEXT_FRAME_BUFFER_REQUEST_ST        =   3'h3;
    localparam      [3 - 1     : 0]     UPDATE_FRAME_BUFFER_ST              =   3'h4;
    localparam      [3 - 1     : 0]     WAIT_FOR_NEXT_TXN_ST                =   3'h5;
    localparam      [3 - 1     : 0]     ERROR_ST                            =   3'h6;


    wire                                    next_line_request, data_burst_finished, next_frame_buffer_req, reset_fifo;
    wire                                    vf_valid, uvc_ready;
    wire    [BYTE_WIDTH - 1     : 0]        vf_byte;
    wire    [20 - 1             : 0]        buffer_offset;
    wire    [8 - 1              : 0]        wr_data_count;
    wire    [72 - 1             : 0]        din;
    wire                                    start_of_frame, start_of_frame_error, start_of_frame_error_axi, end_of_error_pause;
    wire    [9 - 1              : 0]        dout;
    wire                                    valid;

    reg                                     idle_st, write_line_addr_txn_st, wait_for_next_txn_st, wait_for_data_burst_finished_st, next_frame_buffer_request_st, update_frame_buffer_st, error_st;
    reg     [3 - 1              : 0]        pr_state, next_state;
    reg     [PIXEL_WIDTH - 1    : 0]        pixel;
    reg     [9 - 1              : 0]        line_num;
    reg                                     rvalid_d;
    reg    [8 - 1              : 0]         burst_data_idx;
    reg    [5 - 1              : 0]         error_pause_cnt;

    (* ASYNC_REG="TRUE" *)  reg [3 - 1  : 0]     start_of_frame_error_sync = 2'd0;


    // dbg
    reg     [PIXEL_WIDTH - 1    : 0]        pixel_dbg;
// ============================================================================================================================

// 
    assign      arlen                       =   N_ROWS/4 - 1;
    assign      arsize                      =   3'b011;
    assign      arburst                     =   2'b01; 
    assign      rready                      =   1'b1;
    assign      arvalid                     =   write_line_addr_txn_st;
    assign      data_burst_finished         =   (N_ROWS/4 == burst_data_idx) ? 1'b1 : 1'b0;
    assign      next_frame_buffer_req       =   (N_LINES == line_num) ? 1'b1 : 1'b0;
    assign      buffer_offset               =   {line_num, LINE_STRIDE};
    assign      araddr                      =   frame_buffer_addr + buffer_offset;
    assign      next_line_request           =   (8'd64 > wr_data_count) ? 1'b1: 1'b0;
    assign      start_of_frame              =   (9'd1 == line_num && 8'd0 == burst_data_idx) ? 1'b1 : 1'b0;

    assign      start_of_frame_error        =   ~dout[8] & valid & vf_sof;
    assign      start_of_frame_error_axi    =   ~start_of_frame_error_sync[2] & start_of_frame_error_sync[1];
    assign      end_of_error_pause          =   (5'h1F == error_pause_cnt) ? 1'b1 : 1'b0;
    assign      reset_fifo                  =   (5'd0 < error_pause_cnt  && 5'd17 > error_pause_cnt) ? 1'b1 : 1'b0;
    
    assign      vf_valid                    =   valid & ~error_st & ~idle_st;
    assign      vf_byte                     =   dout[7:0];
    // assign      vf_valid                    =   1'b1;
    // assign      vf_byte                     =   pixel_dbg;


    always @ (posedge clk_60MHz, negedge rst_n)
        begin
            if (!rst_n)
                begin
                    pixel_dbg               <=  8'd0;
                end
            else 
                begin
                    if (vf_sof)
                        begin
                            pixel_dbg       <=  pixel_dbg   +   8'd64;
                        end
                end
        end



// async
    always @ (posedge axi_clk)
        begin
            start_of_frame_error_sync[2 : 0]       <=  {start_of_frame_error_sync[1 : 0], start_of_frame_error};
        end

// FSM async
    always @ (pr_state, arvalid, arready, data_burst_finished, next_line_request, next_frame_buffer_req, start_of_frame_error_axi, end_of_error_pause)
        begin
            idle_st                             =   1'b0;
            write_line_addr_txn_st              =   1'b0;
            wait_for_next_txn_st                =   1'b0;
            next_frame_buffer_request_st        =   1'b0;
            update_frame_buffer_st              =   1'b0;
            wait_for_data_burst_finished_st     =   1'b0;
            error_st                            =   1'b0;

            case(pr_state)
                IDLE_ST:   
                    begin
                        next_state                  =   IDLE_ST;
                        idle_st                     =   1'b1;
                        
                        if (start_of_frame_error_axi)
                            begin
                                next_state          =   ERROR_ST;
                            end
                        else
                            begin
                                next_state          =   WRITE_LINE_ADDR_TXN_ST;
                            end
                    end

                WRITE_LINE_ADDR_TXN_ST:   
                    begin
                        next_state                  =   WRITE_LINE_ADDR_TXN_ST;
                        write_line_addr_txn_st      =   1'b1;

                        if (start_of_frame_error_axi)
                            begin
                                next_state          =   ERROR_ST;
                            end
                        else if (arvalid & arready)
                            begin
                                next_state          =   WAIT_FOR_DATA_BURST_FINISHED_ST;
                            end
                    end

                WAIT_FOR_DATA_BURST_FINISHED_ST:   
                    begin
                        next_state                          =   WAIT_FOR_DATA_BURST_FINISHED_ST;
                        wait_for_data_burst_finished_st     =   1'b1;

                        if (start_of_frame_error_axi)
                            begin
                                next_state          =   ERROR_ST;
                            end
                        else if (data_burst_finished)
                            begin
                                next_state                  =   WAIT_FOR_NEXT_TXN_ST;
                            end
                    end

                WAIT_FOR_NEXT_TXN_ST:   
                    begin
                        next_state                  =   WAIT_FOR_NEXT_TXN_ST;
                        wait_for_next_txn_st        =   1'b1;
                        
                        if (start_of_frame_error_axi)
                            begin
                                next_state          =   ERROR_ST;
                            end
                        else if (next_frame_buffer_req)
                            begin
                                next_state          =   NEXT_FRAME_BUFFER_REQUEST_ST;
                            end
                        else if (next_line_request)
                            begin
                                next_state          =   WRITE_LINE_ADDR_TXN_ST;
                            end
                    end

                NEXT_FRAME_BUFFER_REQUEST_ST:   
                    begin
                        next_state                  =   NEXT_FRAME_BUFFER_REQUEST_ST;
                        next_frame_buffer_request_st      =   1'b1;
                        
                        if (start_of_frame_error_axi)
                            begin
                                next_state          =   ERROR_ST;
                            end
                        else if (next_line_request)
                            begin
                                next_state          =   UPDATE_FRAME_BUFFER_ST;
                            end
                    end

                UPDATE_FRAME_BUFFER_ST:   
                    begin
                        next_state                  =   WRITE_LINE_ADDR_TXN_ST;
                        update_frame_buffer_st      =   1'b1;
                    end

                ERROR_ST:   
                    begin
                        next_state                  =   ERROR_ST;
                        error_st                    =   1'b1;
                        
                        if (end_of_error_pause)
                            begin
                                next_state          =   IDLE_ST;
                            end
                    end

                default:    
                    begin
                        next_state                  =   IDLE_ST;
                    end
            endcase
        end

// FSM sync and smth else...
    always @ (posedge axi_clk, negedge rst_n)
        begin
            if (!rst_n)
                begin
                    pr_state                            <=  IDLE_ST;
                    line_num                            <=  9'd0;
                    burst_data_idx                      <=  8'd0;
                    error_pause_cnt                     <=  5'd0;
                    next_frame_buffer_request           <=  1'b0;
                end
            else
                begin

                    pr_state                            <=  next_state;

                    next_frame_buffer_request           <=  next_frame_buffer_req;
                    
                    if (idle_st | update_frame_buffer_st | error_st)
                        begin
                            line_num                    <=  9'h000;
                        end
                    else if (write_line_addr_txn_st)
                        begin
                            line_num                    <=  (arvalid & arready) ? line_num + 1'b1 : line_num;
                        end

                    if (wait_for_data_burst_finished_st)
                        begin
                            burst_data_idx              <=  (rvalid & rready) ? burst_data_idx + 1'b1 : burst_data_idx; 
                        end
                    else 
                        begin
                            burst_data_idx              <=  8'd0; 
                        end

                    if (error_st)
                        begin
                            error_pause_cnt             <=  error_pause_cnt + 1'b1; 
                        end
                    else 
                        begin
                            error_pause_cnt              <=  5'd0; 
                        end



                end
        end

// Frame FIFO
    assign  din     =   {start_of_frame,    rdata[7:0],      1'b0, rdata[15:8],  1'b0, rdata[23:16], 1'b0, rdata[31:24],
                         1'b0,              rdata[39:32],    1'b0, rdata[47:40], 1'b0, rdata[55:48], 1'b0, rdata[63:56]};

    UvcFifo uvc_fifo (
        .rst                          (~rst_n | reset_fifo),        // input wire rst
        .wr_clk                       (axi_clk),                    // input wire wr_clk
        .rd_clk                       (clk_60MHz),                  // input wire rd_clk
        .din                          (din),                        // input wire [71 : 0] din
        .wr_en                        (rvalid & rready),            // input wire wr_en
        .rd_en                        (vf_valid & uvc_ready),       // input wire rd_en
        .dout                         (dout),                       // output wire [8 : 0] dout
        .full                         (full),                       // output wire full
        .empty                        (empty),                      // output wire empty
        .valid                        (valid),                      // output wire valid
        .wr_data_count                (wr_data_count),              // output wire [7 : 0] wr_data_count
        .wr_rst_busy                  (wr_rst_busy),                // output wire wr_rst_busy
        .rd_rst_busy                  (rd_rst_busy)                 // output wire rd_rst_busy
    );




// USB-UVC camera device
    UsbUvcPort #(
        .FRAME_W                    (FRAME_W),          // video-frame width  in pixels, must be a even number
        .FRAME_H                    (FRAME_H),          // video-frame height in pixels, must be a even number
        .DEBUG                      ("FALSE")           // If you want to see the debug info of USB device core, set this parameter to "TRUE"
    ) usb_uvc_port (
        .rstn                       (rst_n),
        .clk_60MHz                  (clk_60MHz),
        // USB signals
        .usb_dp_pull                (usb_dp_pull),
        .usb_dp_i                   (usb_dp_i),
        .usb_dp_o                   (usb_dp_o),
        .usb_dp_t                   (usb_dp_t),
        .usb_dn_i                   (usb_dn_i),
        .usb_dn_o                   (usb_dn_o),
        .usb_dn_t                   (usb_dn_t),
        // USB reset output 
        .usb_rstn                   (led),              // 1: connected , 0: disconnected (when USB cable unplug, or when system reset (rstn=0))
        // video frame fetch interface
        .uvc_ready                  (uvc_ready),        // one clk_60MHz pulse: uvc is ready to accept data byte
        .vf_sof                     (vf_sof),           // one clk_60MHz pulse before every frame started
        .vf_data                    (vf_byte),

        // If 'vf_valid' high when 'uvc_ready' is asserted - 'vf_data' (1 byte) is read and sent in current packet transmitted. Max packet size - 800 Bytes. 1 packet per 1 ms.
        // If low - current packet is finilized and sent (empty packet is allowed). Next packet will be requested in 1 ms after current packet was started.
        .vf_valid                   (vf_valid)
    );

//
    // ila_debugger #(
    //     .PROFILE_BIT_WIDTH(24),
    //     .PROFILE_BUS_WIDTH(256))
    // u_ila_debugger (
    //     .clk            (axi_clk),

    //     .profile_bit    ({
    //                         4'd0, rvalid, rready, arvalid, arready,
    //                         data_burst_finished, start_of_frame, error_st, update_frame_buffer_st, wait_for_next_txn_st, wait_for_data_burst_finished_st, write_line_addr_txn_st, idle_st,
    //                         rst_n, valid, next_frame_buffer_req, reset_fifo, start_of_frame_error, vf_sof, uvc_ready, vf_valid
    //                     }),
    //     .profile_bus    ({
    //                     16'hDEAD,
    //                     {7'd0, din[8:0]},
    //                     rdata[63:48],
    //                     rdata[47:32],
    //                     rdata[31:16],
    //                     rdata[15:0],
    //                     araddr[31:16],
    //                     araddr[15:0],

    //                     16'hDEAD,
    //                     {13'd0, pr_state},
    //                     {11'd0, error_pause_cnt},
    //                     {8'd0, burst_data_idx},
    //                     {7'd0, line_num},
    //                     {7'd0, dout},
    //                     {8'd0, wr_data_count},
    //                     {8'd0, vf_byte}
    //                     })
    //     );


endmodule
// ============================================================================================================================






