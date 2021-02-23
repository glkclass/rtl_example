//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class reg_single_seq extends uvm_sequence #(dut_in_txn);
    `uvm_object_utils(reg_single_seq)

    extern function new(string name = "reg_single_seq");
    extern task body();
endclass


function reg_single_seq::new(string name = "reg_single_seq");
    super.new(name);
endfunction


task reg_single_seq::body();
    dut_in_txn txn;
    txn = dut_in_txn::type_id::create("txn");
    start_item(txn);
    assert ( txn.reg_h.randomize() );
    assert ( txn.input_h.randomize() );
    finish_item(txn);
endtask
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class input_single_seq extends uvm_sequence #(dut_in_txn);
    `uvm_object_utils(input_single_seq)

    extern function new(string name = "input_single_seq");
    extern task body();
endclass


function input_single_seq::new(string name = "input_single_seq");
    super.new(name);
endfunction


task input_single_seq::body();
    dut_in_txn txn;
    txn = dut_in_txn::type_id::create("txn");
    start_item(txn);
    assert ( txn.input_h.randomize() );
    txn.reg_valid = 1'b0; //don't apply 'reg' values, only 'inputs'
    finish_item(txn);
endtask
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
