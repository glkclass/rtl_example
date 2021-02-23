class dut_coverage_collector extends dut_coverage_collector_base #(dut_in_txn);
    `uvm_component_utils(dut_coverage_collector)

    covergroup cover_dut_txn (string name);
        option.per_instance = 1;
        option.name = name;

        cover_reg_foo_y_gain_sft:      coverpoint dut_txn_h.reg_h.foo_y_gain_sft
            {
                bins corner_values[] = {0, 1, p_y_gain_sft_max-1, p_y_gain_sft_max};
            }

        cover_reg_foo_thres_bayer:     coverpoint dut_txn_h.reg_h.foo_thres_bayer
            {
                bins corner_values[] = {0, 1, p_thres_bayer_max-1, p_thres_bayer_max};
            }

        cover_reg_foo_pedestal:        coverpoint dut_txn_h.reg_h.foo_pedestal
            {
                bins corner_values[] = {0, 1, p_pedestal_max-1, p_pedestal_max};
            }

        cover_arr_type:                 coverpoint dut_txn_h.input_h.arr_type;

        cover_y_lsb:                    coverpoint dut_txn_h.input_h.y_lsb;

        cover_coeff_0:                  coverpoint dut_txn_h.input_h.coeff_vec[0]
            {
                bins corner_values[] = {0, 1, p_coeff_max-1, p_coeff_max};
            }

        cover_coeff_1:                  coverpoint dut_txn_h.input_h.coeff_vec[1]
            {
                bins corner_values[] = {0, 1, p_coeff_max-1, p_coeff_max};
            }

        cover_coeff_2:                  coverpoint dut_txn_h.input_h.coeff_vec[2]
            {
                bins corner_values[] = {0, 1, p_coeff_max-1, p_coeff_max};
            }

        cover_pixel_0:                  coverpoint dut_txn_h.input_h.pixel[0]
            {
                bins corner_values[] = {0, 1, p_pixel_max-1, p_pixel_max};
            }

        cover_pixel_1:                  coverpoint dut_txn_h.input_h.pixel[1]
            {
                bins corner_values[] = {0, 1, p_pixel_max-1, p_pixel_max};
            }

    endgroup


    extern function new(string name = "dut_coverage_collector", uvm_component parent=null);
    extern function void check_coverage();
    extern function void sample_coverage();
endclass


function dut_coverage_collector::new(string name = "dut_coverage_collector", uvm_component parent=null);
    super.new(name, parent);
    cover_dut_txn = new("dut_in");
endfunction


function void dut_coverage_collector::sample_coverage();
    cover_dut_txn.sample ();
endfunction


function void dut_coverage_collector::check_coverage();
    cov_result["y_gain_shift"]  = cover_dut_txn.cover_reg_foo_y_gain_sft.get_inst_coverage();
    cov_result["thres_bayer"]   = cover_dut_txn.cover_reg_foo_thres_bayer.get_inst_coverage();
    cov_result["pedestal"]      = cover_dut_txn.cover_reg_foo_pedestal.get_inst_coverage();
    cov_result["arr_type"]      = cover_dut_txn.cover_arr_type.get_inst_coverage();
    cov_result["y_lsb"]         = cover_dut_txn.cover_y_lsb.get_inst_coverage();
    cov_result["coeff_0"]       = cover_dut_txn.cover_coeff_0.get_inst_coverage();
    cov_result["coeff_1"]       = cover_dut_txn.cover_coeff_1.get_inst_coverage();
    cov_result["coeff_2"]       = cover_dut_txn.cover_coeff_2.get_inst_coverage();
    cov_result["pixel_0"]       = cover_dut_txn.cover_pixel_0.get_inst_coverage();
    cov_result["pixel_1"]       = cover_dut_txn.cover_pixel_1.get_inst_coverage();

    `uvm_info("COVERAGE",
        $sformatf
        (
            "\nregs[0..2]: %0d %0d %0d cov: %.2f %.2f %.2f\ni_arr_type: %0d cov: %.2f\ni_y_lsb: %0d cov: %.2f\n\
coeff_vec[0..2]: %0d %0d %0d cov: %.2f %.2f %.2f\ni_pixels[0..1]: %0d %0d cov: %.2f %.2f",
            dut_txn_h.reg_h.foo_y_gain_sft, dut_txn_h.reg_h.foo_thres_bayer, dut_txn_h.reg_h.foo_pedestal,
            cov_result["y_gain_shift"], cov_result["thres_bayer"], cov_result["pedestal"],
            dut_txn_h.input_h.arr_type, cov_result["arr_type"],
            dut_txn_h.input_h.y_lsb, cov_result["y_lsb"],
            dut_txn_h.input_h.coeff_vec[0], dut_txn_h.input_h.coeff_vec[1], dut_txn_h.input_h.coeff_vec[2],
            cov_result["coeff_0"], cov_result["coeff_1"], cov_result["coeff_2"],
            dut_txn_h.input_h.pixel[0], dut_txn_h.input_h.pixel[1],
            cov_result["pixel_0"], cov_result["pixel_1"]
        ),
        UVM_FULL)

        progress_bar_h.display();
        if (34 == progress_bar_h.cnt)
            begin
                dut_handler_h.stop_test("Functional coverage target achieved");  // finish current test
            end
endfunction
