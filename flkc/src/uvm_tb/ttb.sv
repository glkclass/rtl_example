module tb;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import dut_tb_param_pkg::*;
    import dut_test_pkg::*;

    bit clk, rstn;

    dut_if dut_if_h
    (
        .clk    (clk),
        .rstn   (rstn)
    );

    dut_wrp dut
    (
        dut_if_h
    );

    initial
        begin : l_clk
            clk = 1'b0;
            forever
                #(p_clk_period/2) clk = ~clk;
        end


    initial
        begin : l_rstn
            rstn = 1'b0;
            #p_rstn_period rstn = 1'b1;
        end

    initial
        begin : l_main
            $timeformat(-9, 0, "ns", 8);
            uvm_config_db #(virtual dut_if)::set(null, "uvm_test_top", "dut_if", dut_if_h);
            run_test();
        end
endmodule
