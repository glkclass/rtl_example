virtual class dut_coverage_collector_base #(type t_dut_txn = dut_txn_base) extends uvm_subscriber #(t_dut_txn);
    `uvm_component_utils(dut_coverage_collector_base)

    dut_handler                 dut_handler_h;
    dut_progress_bar            progress_bar_h;

    t_dut_txn                   dut_txn_h;
    real                        cov_result[string];

    extern function new(string name = "dut_coverage_collector_base", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern function void write(t_dut_txn t);
    pure virtual  function void sample_coverage();
    pure virtual  function void check_coverage();
endclass


function dut_coverage_collector_base::new(string name = "dut_coverage_collector_base", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_coverage_collector_base::build_phase(uvm_phase phase);
    progress_bar_h = new("progress_bar_h", this);
    dut_txn_h = t_dut_txn::type_id::create("dut_txn_h");

    // extract dut_handler
    if (!uvm_config_db #(dut_handler)::get(this, "", "dut_handler", dut_handler_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'dut_handler' from config db")
endfunction


function void dut_coverage_collector_base::write(t_dut_txn t);
    dut_txn_h.copy (t);
    sample_coverage();
    check_coverage();
endfunction

