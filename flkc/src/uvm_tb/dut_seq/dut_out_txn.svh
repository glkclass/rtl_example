// output dut transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_out_txn extends dut_txn_base;
    `uvm_object_utils(dut_out_txn)

    logic  [p_k_bit - 1 : 0]                    pixel [p_ch_num];

    extern function new(string name = "dut_out_txn");
    extern virtual function void do_copy (uvm_object rhs); // make a deep copy
    extern virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
    extern virtual function string convert2string (); // represent 'txn content' as string
    extern virtual function vector pack2vector (); // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    extern virtual function string sformatf_pair (uvm_object txn); // print content of both transactions to compare
    extern function void read (virtual dut_if dut_vif); // read 'txn content' from interface
endclass


function dut_out_txn::new(string name = "dut_out_txn");
    super.new(name);
endfunction


function void dut_out_txn::do_copy (uvm_object rhs);
    dut_out_txn _rhs;
    if(!$cast(_rhs, rhs))
        begin
            `uvm_error("TXN_DO_COPY", "Txn cast was failed")
            return;
        end
    super.do_copy(rhs); // chain the copy with parent classes

    pixel = _rhs.pixel;
endfunction


function bit dut_out_txn::do_compare(uvm_object rhs, uvm_comparer comparer);
    dut_out_txn _rhs;
    // If the cast fails, comparison has also failed
    // A check for null is not needed because that is done in the compare() function which calls do_compare()
    if(!$cast(_rhs, rhs))
        begin
            return 0;
        end

    return ( super.do_compare(rhs, comparer) && (pixel == _rhs.pixel) );
endfunction


function string dut_out_txn::convert2string();
    return $sformatf ("o_pixel[0..1]: %0d %0d", pixel[0], pixel[1]);
endfunction


function vector dut_out_txn::pack2vector();
    return {pixel}; // int[2]
endfunction


function void dut_out_txn::unpack4vector(vector packed_txn);
    pixel = { packed_txn[0], packed_txn[1] };
endfunction


function string dut_out_txn::sformatf_pair (uvm_object txn);
    dut_out_txn _txn;
    string s;
    if(!$cast(_txn, txn))
        begin
            `uvm_error("TXN_PRINT_PAIR", "Txn cast was failed")
            return "";
        end
    s = $sformatf ("o_pixel[0..1]: %0d %0d    vs    %0d %0d ", pixel[0], pixel[1], _txn.pixel[0], _txn.pixel[1]);
return s;
endfunction


function void dut_out_txn::read(virtual dut_if dut_vif);
    content_valid = dut_vif.OUTPUT_VALID;
    if (1'b1 == content_valid)
        begin
            pixel[0]    = dut_vif.o_PIXELS[p_k_bit - 1 : 0];
            pixel[1]    = dut_vif.o_PIXELS[2*p_k_bit - 1 : p_k_bit];
        end
endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
