// Helper core. Reset Usb core when working mode changed: Uvc <--> Cdc
module UsbResetBridge(
    
    input rst_n, clk, usb_working_mode,
    output reg usb_reset_n
);

reg                     usb_working_mode_d;
reg [6 - 1  : 0]        reset_cnt;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            reset_cnt               <=  6'd0;            
            usb_working_mode_d      <=  1'b0;
            usb_reset_n             <=  1'b1;
        end
    else
        begin
            usb_working_mode_d      <=  usb_working_mode;

            if (usb_working_mode ^ usb_working_mode_d)
                begin
                    usb_reset_n     <=  1'b0;
                end
            else if (6'h3F == reset_cnt)
                begin
                    usb_reset_n     <=  1'b1;
                end

            if (~usb_reset_n)
                begin
                    reset_cnt       <= reset_cnt + 1'b1;
                end
            else 
                begin
                    reset_cnt       <= 6'd0;
                end

        end
end
endmodule
