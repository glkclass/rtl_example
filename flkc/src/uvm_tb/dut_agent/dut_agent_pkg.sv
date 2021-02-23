`timescale 1ns/1ns
package dut_agent_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import dut_param_pkg::*;
    import dut_tb_param_pkg::*;
    import dut_sequence_pkg::*;
    `include "dut_progress_bar.svh"
    `include "dut_driver.svh"
    `include "dut_monitor.svh"
    `include "dut_tp_monitor.svh"
    `include "dut_agent_cfg.svh"
    `include "dut_agent.svh"
endpackage
