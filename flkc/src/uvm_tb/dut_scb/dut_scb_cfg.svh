class dut_scb_cfg extends uvm_object;
    `uvm_object_utils(dut_scb_cfg)

    bit has_coverage_collector = 1'b1;
    bit has_predictor = 1'b1;
    bit has_evaluator = 1'b1;

    extern function new(string name = "dut_scb_cfg");
endclass

function dut_scb_cfg::new(string name = "dut_scb_cfg");
    super.new(name);
endfunction



