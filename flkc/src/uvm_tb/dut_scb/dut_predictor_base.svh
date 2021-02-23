class dut_predictor_base #(type t_dut_in_txn = dut_txn_base, t_dut_out_txn = dut_txn_base) extends uvm_subscriber #(t_dut_in_txn);
    `uvm_component_param_utils (dut_predictor_base #(dut_in_txn, dut_out_txn))

    uvm_analysis_port #(t_dut_out_txn) dut_out_gold_aport;
    t_dut_in_txn dut_in_txn_h;
    t_dut_out_txn dut_out_gold_txn_tmp_h;  // txn for temporary store
    chandle gold_ref_h;
    int log[p_log_buffer_size];

    extern function new(string name = "dut_predictor_base", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern function void write(t_dut_in_txn t);
    extern function vector pack_dut_in_txn ();
    extern function void unpack_dut_out_txn (vector packed_txn);
    extern virtual function void gold_ref (chandle gold_ref_h);
endclass


function dut_predictor_base::new(string name = "dut_predictor_base", uvm_component parent=null);
    super.new(name, parent);
endfunction


function void dut_predictor_base::build_phase(uvm_phase phase);
    dut_out_gold_aport = new("dut_out_gold_aport", this);
    dut_out_gold_txn_tmp_h = t_dut_out_txn::type_id::create("dut_out_gold_txn_tmp_h");
    dut_in_txn_h = t_dut_in_txn::type_id::create("dut_in_txn_h");
    gold_ref_h = dut_gold_ref_new(); // create cpp-class containing cpp-references
endfunction


function void dut_predictor_base::write(t_dut_in_txn t);
    t_dut_out_txn dut_out_gold_txn_h;

    dut_in_txn_h.copy(t);// make copy of the input dut transaction
    gold_ref(gold_ref_h);
    $cast(dut_out_gold_txn_h, dut_out_gold_txn_tmp_h.clone()); // make a deep copy of the input dut transaction
    dut_out_gold_aport.write(dut_out_gold_txn_h);
endfunction


function void dut_predictor_base::gold_ref (chandle gold_ref_h);
    `uvm_error("VFNOTOVRDN", "Override 'gold_ref()' method")
endfunction


function vector dut_predictor_base::pack_dut_in_txn ();
    vector packed_txn = dut_in_txn_h.pack2vector();
    return packed_txn;
endfunction


function void dut_predictor_base::unpack_dut_out_txn (vector packed_txn);
    dut_out_gold_txn_tmp_h.unpack4vector(packed_txn);
endfunction









