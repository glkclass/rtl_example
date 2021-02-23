class recorded_txn_test extends dut_test_base;
    `uvm_component_utils(recorded_txn_test)
    extern function new(string name = "recorded_txn_test", uvm_component parent = null);
    extern task run_phase(uvm_phase phase);
endclass


function recorded_txn_test::new(string name = "recorded_txn_test", uvm_component parent = null);
    super.new(name, parent);
endfunction


task recorded_txn_test::run_phase(uvm_phase phase);
    recorded_txn_scenario seq_h;
    seq_h = recorded_txn_scenario::type_id::create("seq_h");
    phase.raise_objection(this, "recorded_txn_test started");
    @ (posedge dut_vif.rstn);
    fork
        seq_h.start(dut_env_h.dut_in_agent_h.dut_sequencer_h);
        dut_handler_h.wait_for_stop_test();
    join_any
    phase.drop_objection(this, "recorded_txn_test finished");
endtask
