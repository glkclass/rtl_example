`timescale 1ns/1ns
package dut_sequence_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"


    import typedef_pkg::*;
    import dut_param_pkg::*;
    import dut_tb_param_pkg::*;
    import dut_handler_pkg::*;
    `include "dut_txn_base.svh"
    `include "dut_in_txn.svh"
    `include "dut_out_txn.svh"
    `include "dut_tp_txn.svh"
    `include "single_seq.svh"
    `include "series_seq.svh"
endpackage

