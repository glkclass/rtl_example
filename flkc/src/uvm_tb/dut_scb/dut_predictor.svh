class dut_predictor #(type t_dut_in_txn = dut_txn_base, t_dut_out_txn = dut_txn_base) extends dut_predictor_base #(t_dut_in_txn, t_dut_out_txn);
    `uvm_component_param_utils(dut_predictor #(dut_in_txn, dut_out_txn))

    int in_vec[], out_vec[2];

    extern function new(string name = "dut_predictor", uvm_component parent=null);
    extern virtual function void gold_ref (chandle gold_ref_h);
endclass


function dut_predictor::new(string name = "dut_predictor", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_predictor::gold_ref(chandle gold_ref_h);
    in_vec = pack_dut_in_txn ();  // pack to 'vector of int'
    foo_correction (gold_ref_h, in_vec, out_vec, log);
    unpack_dut_out_txn (out_vec);  // unpack from 'vector of int'
endfunction

