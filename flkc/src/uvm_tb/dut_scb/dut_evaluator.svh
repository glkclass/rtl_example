class dut_evaluator extends uvm_component;
    `uvm_component_utils(dut_evaluator)

    dut_handler dut_handler_h;

    uvm_analysis_export #(dut_out_txn)      dut_out_gold_export, dut_out_rtl_export;
    uvm_analysis_export #(dut_tp_txn)       dut_tp_gold_export, dut_tp_rtl_export;
    uvm_analysis_export #(dut_in_txn)       dut_in_export;
    uvm_analysis_port #(dut_in_txn)         dut_in_aport;

    uvm_tlm_analysis_fifo #(dut_in_txn)     dut_in_fifo;
    uvm_tlm_analysis_fifo #(dut_out_txn)    dut_out_gold_fifo, dut_out_rtl_fifo;


    uvm_barrier                             synch_seq_br_h;
    dut_progress_bar                        progress_bar_h;

    bit has_predictor, has_coverage_collector;

    extern function new(string name = "dut_evaluator", uvm_component parent=null);
    extern function void build_phase (uvm_phase phase);
    extern function void connect_phase (uvm_phase phase);
    extern task run_phase (uvm_phase phase);
    extern task synch_seq();
endclass


function dut_evaluator::new(string name = "dut_evaluator", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_evaluator::build_phase (uvm_phase phase);
    progress_bar_h = new("progress_bar_h", this);

    // extract dut_handler
    if (!uvm_config_db #(dut_handler)::get(this, "", "dut_handler", dut_handler_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'dut_handler' from config db")

    // extract barrier for sequences synchronization
    if (!uvm_config_db #(uvm_barrier)::get(this, "", "synch_seq_barrier", synch_seq_br_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'synch_seq_barrier' from config db")


    if (!uvm_config_db #(bit)::get(this, "", "has_predictor", has_predictor))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'has_predictor' from config db}")

    if (!uvm_config_db #(bit)::get(this, "", "has_coverage_collector", has_coverage_collector))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'has_coverage_collector' from config db}")

    // create input ports
    if (has_predictor)
        begin
            dut_out_gold_export = new ("dut_out_gold_export", this);
        end
    dut_out_rtl_export = new ("dut_out_rtl_export", this);
    dut_tp_rtl_export = new ("dut_tp_rtl_export", this);

    dut_in_export = new ("dut_in_export", this);

    if (has_coverage_collector)
        begin
            dut_in_aport = new("dut_in_aport", this);
        end

    // create fifo buffers
    if (has_predictor)
        begin
            dut_out_gold_fifo = new ("dut_out_gold_fifo", this);
        end
    dut_out_rtl_fifo = new ("dut_out_rtl_fifo", this);
    dut_in_fifo = new ("dut_in_fifo", this);
endfunction


function void dut_evaluator::connect_phase (uvm_phase phase);
    // connect input ports with appropriate fifo buffers
    dut_in_export.connect(dut_in_fifo.analysis_export);
    dut_out_rtl_export.connect(dut_out_rtl_fifo.analysis_export);
    if (has_predictor)
        begin
            dut_out_gold_export.connect(dut_out_gold_fifo.analysis_export);
        end
endfunction


task dut_evaluator::run_phase( uvm_phase phase );
    dut_out_txn dut_out_gold_txn_h, dut_out_rtl_txn_h;
    dut_in_txn dut_in_txn_h;
    forever
        begin
            // extract output rtl and gold txn to be evaluated and appropriate input txn
            dut_out_gold_fifo.get(dut_out_gold_txn_h);
            dut_out_rtl_fifo.get(dut_out_rtl_txn_h);
            dut_in_fifo.get(dut_in_txn_h);

            // compare results
            if (!dut_out_rtl_txn_h.compare(dut_out_gold_txn_h))
                begin
                    `uvm_info("COMPARE", {"dut_in content:\n", dut_in_txn_h.sprint()}, UVM_HIGH)
                    `uvm_error("COMPARE", {"'gold' and 'rtl' results don't match:\n", dut_out_gold_txn_h.sformatf_pair(dut_out_rtl_txn_h)})
                    dut_handler_h.fail(dut_in_txn_h.pack2vector());
                end
            else
                begin
                    dut_handler_h.success();
                    dut_in_aport.write(dut_in_txn_h);  // send input txn to coverage collector (only when appropriate output txn was successfull)
                end

            synch_seq();// finish processing of all content of the previous sequence before let the next one to proceed...
            progress_bar_h.display($sformatf("Success/Fails = %0d/%0d", dut_handler_h.n_success, dut_handler_h.n_fails));
        end
endtask


// finish processing of all content of the previous sequence before let the next one to proceed...
task dut_evaluator::synch_seq();
    bit seq_finished = (1 == synch_seq_br_h.get_num_waiters()) ? 1'b1 : 1'b0;
    if (1'b1 == seq_finished && 0 == dut_out_gold_fifo.used())  // current sequence was finished and it's content was fully processed
        begin
            synch_seq_br_h.wait_for();  // let the next sequence to proceed
        end
endtask

