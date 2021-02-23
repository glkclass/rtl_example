class dut_txn_base extends uvm_sequence_item;
    `uvm_object_utils (dut_txn_base)
    bit content_valid; // validates transaction content
    bit input_valid, reg_valid; // validates transaction 'input' and 'reg' part

    extern function new (string name = "dut_txn_base");
    // extern virtual function void do_copy (uvm_object rhs);  // make a deep copy
    // extern virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
    extern virtual function void do_print (uvm_printer printer);  // print transaction content
    extern virtual function string convert2string ();  // represent 'txn content' as string
    extern virtual function vector pack2vector (); // pack 'txn content' to 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //unpack 'txn content' from 'vector of int'
    extern virtual function void write (virtual dut_if dut_vif);  // write 'txn content' to interface
    extern virtual function void read (virtual dut_if dut_vif);  // read 'txn content' from interface
    extern virtual function void print_pair (uvm_object txn);  // print content of both transactions to compare
endclass


function dut_txn_base::new (string name = "dut_txn_base");
    super.new(name);
    input_valid = 1'b1;
    reg_valid = 1'b1;
endfunction

// function void dut_txn_base::do_copy (uvm_object rhs);
//     `uvm_error("VFNOTOVRDN", "Override 'do_copy (uvm_object rhs)' method")
// endfunction

// function bit dut_txn_base::do_compare (uvm_object rhs, uvm_comparer comparer);
//     `uvm_error("VFNOTOVRDN", "Override 'do_compare (uvm_object rhs, uvm_comparer comparer)' method")
//     return 1'b0;
// endfunction

function void dut_txn_base::do_print (uvm_printer printer);
    string s;
    super.do_print (printer);
    s = "\n-------------------\n";
    printer.m_string = {get_type_name(), " ",  get_name(), s, convert2string()};
endfunction


function string dut_txn_base::convert2string ();
    `uvm_error("VFNOTOVRDN", "Override 'convert2string ()' method")
    return "";
endfunction


function vector dut_txn_base::pack2vector ();
    `uvm_error("VFNOTOVRDN", "Override 'pack2vector ()' method")
    return ({});
endfunction


function void dut_txn_base::unpack4vector (vector packed_txn);
    `uvm_error("VFNOTOVRDN", "Override 'unpack4vector (vector packed_txn)' method")
endfunction


function void dut_txn_base::write (virtual dut_if dut_vif);
    `uvm_error("VFNOTOVRDN", "Override 'write (virtual dut_if dut_vif)' method")
endfunction


function void dut_txn_base::read (virtual dut_if dut_vif);
    `uvm_error("VFNOTOVRDN", "Override 'read (virtual dut_if dut_vif)' method")
endfunction


function void dut_txn_base::print_pair (uvm_object txn);
    `uvm_error("VFNOTOVRDN", "Override 'print_pair (uvm_object txn)' method")
endfunction
