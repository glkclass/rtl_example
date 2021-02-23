package dut_scb_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import typedef_pkg::*;
    import dut_tb_param_pkg::*;
    import dut_param_pkg::*;
    import dut_handler_pkg::*;
    import dut_sequence_pkg::*;
    `include "dut_coverage_collector_base.svh"
    `include "dut_coverage_collector.svh"
    `include "dut_evaluator.svh"
    `include "dut_dpi_prototypes.svh"
    `include "dut_predictor_base.svh"
    `include "dut_predictor.svh"
    `include "dut_scb_cfg.svh"
    `include "dut_scb.svh"
endpackage
