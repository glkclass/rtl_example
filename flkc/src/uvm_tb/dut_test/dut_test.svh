class dut_test extends dut_test_base;
    `uvm_component_utils(dut_test)
    extern function new(string name = "dut_test", uvm_component parent = null);
    extern task run_phase(uvm_phase phase);
endclass

function dut_test::new(string name = "dut_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

task dut_test::run_phase(uvm_phase phase);
    var_reg_scenario seq_h;
    seq_h = var_reg_scenario::type_id::create("seq_h");
    dut_handler_h.recorder_db_mode = WRITE;  // enable store failed txn to 'recorder_db' file
    seq_h.c_length.constraint_mode(0);
    assert ( seq_h.randomize() with { seq_h.length inside {[5:10]}; } );
    phase.raise_objection(this, "dut_test started");
    @ (posedge dut_vif.rstn);
    // uvm_top.print_topology();
    fork
        seq_h.start(dut_env_h.dut_in_agent_h.dut_sequencer_h);
        dut_handler_h.wait_for_stop_test();
    join_any
    phase.drop_objection(this, "dut_test finished");
endtask
