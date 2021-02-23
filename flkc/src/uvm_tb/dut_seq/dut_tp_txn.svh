// dut test point transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_tp_txn extends dut_txn_base;
    `uvm_object_utils(dut_tp_txn)

    logic           [p_foo_gain_bit - 1 : 0]           r_gain_bayer [p_ch_num-1 : 0] [$];
    logic   signed  [p_pixel_x_gain_bit - 1 : 0]        w_pixel_x_gain_scld [p_ch_num-1 : 0] [$];


    extern function new(string name = "dut_tp_txn");
    extern virtual function void do_copy (uvm_object rhs);  // make a deep copy
    extern virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
    extern virtual function string convert2string ();  // represent 'txn content' as string
    extern virtual function vector pack2vector ();  // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    // extern function void write (virtual dut_if dut_vif);  // write 'txn content' to interface
    extern function void read (virtual dut_if dut_vif);  // read 'txn content' from interface
    extern function dut_tp_txn pop_front();  // extract oldest txn

endclass


function dut_tp_txn::new(string name = "dut_tp_txn");
    super.new(name);
endfunction


function void dut_tp_txn::do_copy(uvm_object rhs);
    dut_tp_txn _rhs;
    if(!$cast(_rhs, rhs))
        begin
            `uvm_error("TXN_DO_COPY", "Txn cast was failed")
            return;
        end
    super.do_copy(rhs); // chain the copy with parent classes

    for (int ch = 0; ch < p_ch_num; ch++)
        begin
            r_gain_bayer[ch][0]        = _rhs.r_gain_bayer[ch][0];
            w_pixel_x_gain_scld[ch][0] = _rhs.w_pixel_x_gain_scld[ch][0];
        end
endfunction


function dut_tp_txn dut_tp_txn::pop_front();
    dut_tp_txn txn;

    txn = dut_tp_txn::type_id::create("txn");
    for (int ch = 0; ch < p_ch_num; ch++)
        begin
            txn.r_gain_bayer[ch][0]         = r_gain_bayer[ch].pop_front();
            txn.w_pixel_x_gain_scld[ch][0]  = w_pixel_x_gain_scld[ch].pop_front();
        end

    return txn;
endfunction


function bit dut_tp_txn::do_compare(uvm_object rhs, uvm_comparer comparer);
    dut_tp_txn _rhs;
    // If the cast fails, comparison has also failed
    // A check for null is not needed because that is done in the compare() function which calls do_compare()
    if(!$cast(_rhs, rhs))
        begin
            return 0;
        end

    return (
                super.do_compare(rhs, comparer) &&
                (r_gain_bayer[0][0]            == _rhs.r_gain_bayer[0][0]) &&
                (r_gain_bayer[1][0]            == _rhs.r_gain_bayer[1][0]) &&
                (w_pixel_x_gain_scld[0][0]     == _rhs.w_pixel_x_gain_scld[0][0]) &&
                (w_pixel_x_gain_scld[1][0]     == _rhs.w_pixel_x_gain_scld[1][0])
            );
endfunction


function string dut_tp_txn::convert2string();
    return $sformatf
        (
            "r_gain_bayer[0..1]: %0d %0d\nw_pixel_x_gain_scld [0..1]: %0d %0d\n",
            r_gain_bayer[0][0],
            r_gain_bayer[1][0],
            w_pixel_x_gain_scld[0][0],
            w_pixel_x_gain_scld[1][0]
        );
endfunction


function vector dut_tp_txn::pack2vector();
    return
        {
            r_gain_bayer[0][0],
            r_gain_bayer[1][0],
            w_pixel_x_gain_scld[0][0],
            w_pixel_x_gain_scld[1][0]
        };
endfunction


function void dut_tp_txn::unpack4vector(vector packed_txn);
    r_gain_bayer[0][0]          = packed_txn[0];
    r_gain_bayer[1][0]          = packed_txn[1];
    w_pixel_x_gain_scld[0][0]   = packed_txn[2];
    w_pixel_x_gain_scld[1][0]   = packed_txn[3];
endfunction


function void dut_tp_txn::read(virtual dut_if dut_vif);

    if (1'b1 == dut_vif.i_ENA_VEC[0])
        begin
            for (int ch = 0; ch < p_ch_num; ch++)
                begin
                    r_gain_bayer[ch].push_back(dut_vif.r_gain_bayer[ch]);
                end
        end

    if (1'b1 == dut_vif.i_ENA_VEC[1])
        begin
            for (int ch = 0; ch < p_ch_num; ch++)
                begin
                    w_pixel_x_gain_scld[ch].push_back(dut_vif.w_pixel_x_gain_scld[ch]);
                end
        end

    content_valid = dut_vif.OUTPUT_VALID;

endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -





