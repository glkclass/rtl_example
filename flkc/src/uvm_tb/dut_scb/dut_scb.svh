class dut_scb extends uvm_scoreboard;
    `uvm_component_utils(dut_scb)

    uvm_analysis_export #(dut_in_txn) dut_in_export;
    uvm_analysis_export #(dut_out_txn) dut_out_export;
    uvm_analysis_export #(dut_tp_txn) dut_tp_export;

    dut_scb_cfg dut_scb_cfg_h;
    dut_predictor #(dut_in_txn, dut_out_txn) dut_predictor_h;
    dut_evaluator dut_evaluator_h;
    dut_coverage_collector dut_coverage_collector_h;

    extern function new(string name = "dut_scb", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass


function dut_scb::new(string name = "dut_scb", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_scb::build_phase(uvm_phase phase);
    // extract config
    if (!uvm_config_db #(dut_scb_cfg)::get(this, "", "dut_scb_cfg", dut_scb_cfg_h))
        `uvm_fatal("dut_scb", "Unable to get 'dut_scb_cfg' from config db}")

    // let know evaluator whether scoreboard contains predictor or no
    uvm_config_db #(bit)::set(this, "dut_evaluator_h", "has_predictor", dut_scb_cfg_h.has_predictor);

    // let know evaluator whether scoreboard contains coverage collector or no
    uvm_config_db #(bit)::set(this, "dut_evaluator_h", "has_coverage_collector", dut_scb_cfg_h.has_coverage_collector);

    // create export to recieve dut input
    if (dut_scb_cfg_h.has_evaluator  | dut_scb_cfg_h.has_predictor)
        begin
            dut_in_export = new("dut_in_export", this);
        end

    // create export to recieve dut output
    if (dut_scb_cfg_h.has_evaluator)
        begin
            dut_out_export = new("dut_out_export", this);
            dut_tp_export = new("dut_tp_export", this);
        end

    // check whether coverage collector is present and create it if so
    if (dut_scb_cfg_h.has_coverage_collector)
        begin
            dut_coverage_collector_h = dut_coverage_collector::type_id::create("dut_coverage_collector_h", this);
        end

    // check whether coverage collector is present and create it if so
    if (dut_scb_cfg_h.has_predictor)
        begin
            dut_predictor_h = dut_predictor #(dut_in_txn, dut_out_txn)::type_id::create("dut_predictor_h", this);
        end

    // check whether coverage collector is present and create it if so
    if (dut_scb_cfg_h.has_evaluator)
        begin
            dut_evaluator_h = dut_evaluator::type_id::create("dut_evaluator_h", this);
        end
endfunction


function void dut_scb::connect_phase(uvm_phase phase);
    if (dut_scb_cfg_h.has_evaluator & dut_scb_cfg_h.has_coverage_collector)
        begin
            dut_evaluator_h.dut_in_aport.connect(dut_coverage_collector_h.analysis_export);
        end

    if (dut_scb_cfg_h.has_predictor)
        begin
            dut_in_export.connect(dut_predictor_h.analysis_export);
        end

    if (dut_scb_cfg_h.has_evaluator)
        begin
            dut_in_export.connect(dut_evaluator_h.dut_in_export);
            dut_out_export.connect(dut_evaluator_h.dut_out_rtl_export);
            dut_tp_export.connect(dut_evaluator_h.dut_tp_rtl_export);
        end

    if (dut_scb_cfg_h.has_predictor & dut_scb_cfg_h.has_evaluator)
        begin
            dut_predictor_h.dut_out_gold_aport.connect(dut_evaluator_h.dut_out_gold_export);
        end
endfunction

