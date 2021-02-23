// 'const regs scenario': 1st txn - apply 'inputs' and 'regs', next n txn - apply only 'inputs', keep 'regs' const - - - - - - - - - - - - - - - - - - - - - -
class const_reg_scenario extends uvm_sequence #(dut_in_txn);
    `uvm_object_utils(const_reg_scenario)

    rand int length;
    constraint c_length { length inside {[1:10]}; }

    uvm_barrier synch_seq_br_h;

    extern function new(string name = "const_reg_scenario");
    extern task body();
endclass


function const_reg_scenario::new(string name = "const_reg_scenario");
    super.new(name);
endfunction


task const_reg_scenario::body();
    //'regs' init
    reg_single_seq regs_seq_h;

    // extract barrier for sequences synchronization
    if (!uvm_config_db #(uvm_barrier)::get(get_sequencer(), "", "synch_seq_barrier", synch_seq_br_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'synch_seq_barrier' from config db")

    regs_seq_h = reg_single_seq::type_id::create("regs_seq_h");
    regs_seq_h.start(get_sequencer(), this);

    //apply 'inputs'
    `uvm_info("SEQNCE", $sformatf("'Const reg scenario' seq length = %0d", length), UVM_HIGH)
    repeat (length)
        begin
            input_single_seq seq_h;
            seq_h = input_single_seq::type_id::create("seq_h");
            seq_h.start(get_sequencer(), this);
        end

    // wait till evaluator will completely finish processing of this sequence
    #p_tco
    synch_seq_br_h.wait_for();
endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


// n 'const regs scenario' sequences - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class var_reg_scenario extends uvm_sequence #(dut_in_txn);
    `uvm_object_utils(var_reg_scenario)

    rand int length;
    constraint c_length { length inside {[1:10]}; }

    extern function new(string name = "var_reg_scenario");
    extern task body();
endclass


function var_reg_scenario::new(string name = "var_reg_scenario");
    super.new(name);
endfunction


task var_reg_scenario::body();
    `uvm_info("SEQNCE", $sformatf("'Varying regs scenario' seq length = %0d", length), UVM_HIGH)

    repeat (length)
        begin
            const_reg_scenario seq_h;
            seq_h = const_reg_scenario::type_id::create("seq_h");
            seq_h.c_length.constraint_mode(0);
            assert ( seq_h.randomize() with { seq_h.length inside {[3:10]}; } );
            seq_h.start(get_sequencer(), this);
        end
endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



// 'recorded txn scenario': txn are read from 'recorder_db' - - - - - - - - - - - - - - - - - - - - - -
class recorded_txn_scenario extends uvm_sequence #(dut_in_txn);
    `uvm_object_utils(recorded_txn_scenario)

    uvm_barrier synch_seq_br_h;
    dut_handler dut_handler_h;

    extern function new(string name = "recorded_txn_scenario");
    extern task body();
endclass

function recorded_txn_scenario::new(string name = "recorded_txn_scenario");
    super.new(name);
endfunction

task recorded_txn_scenario::body();
    int ans = 0, n = 0;
    dut_in_txn txn;
    vector packed_txn;

    // extract barrier for sequences synchronization
    if (!uvm_config_db #(uvm_barrier)::get(get_sequencer(), "", "synch_seq_barrier", synch_seq_br_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'synch_seq_barrier' from config db")

    // extract dut_handler
    if (!uvm_config_db #(dut_handler)::get(get_sequencer(), "", "dut_handler", dut_handler_h))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get 'dut_handler' from config db")

    dut_handler_h.recorder_db_mode = READ;  // enable read from 'recorder_db' file
    do   // 'recorder_db' is opened for read
        begin
            txn = dut_in_txn::type_id::create("txn");
            packed_txn = txn.pack2vector();  // get size of 'packed txn' vector
            ans = dut_handler_h.read4db(packed_txn);  // try to read 'packed txn' content from 'recorder_db'
            if (1 == ans)  // successfull read
                begin
                    start_item(txn);
                    txn.unpack4vector(packed_txn);  // unpack content to txn
                    finish_item(txn);
                    #p_tco
                    `uvm_info("PROGRESS", $sformatf("Txn # %d", n), UVM_HIGH)
                    synch_seq_br_h.wait_for();
                end
            else
                begin
                    if (0 == n)  // first try
                        begin
                            `uvm_info("RECORDER_DB", "Can't read recordered txn", UVM_HIGH)
                        end
                    else  // next tries
                        begin
                            `uvm_info("RECORDER_DB", "There is no more recordered txn", UVM_HIGH)
                        end
                end
            n++;
        end
    while (1 == ans);
endtask
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





