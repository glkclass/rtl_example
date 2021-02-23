class dut_driver #(type t_dut_txn = dut_txn_base) extends uvm_driver #(t_dut_txn);
    `uvm_component_param_utils (dut_driver #(t_dut_txn))

    virtual dut_if dut_vif;
    logic [p_pipeline : 0]          ena_vec; // MSB (ena_vec[p_pipeline]) is used as 'valid signal' for  'dut output'
    rand logic                      dxi_valid, dxi_ready;
    dut_progress_bar                progress_bar_h;

    extern function new(string name = "dut_driver", uvm_component parent=null);
    extern function void build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass


function dut_driver::new(string name = "dut_driver", uvm_component parent=null);
    super.new(name, parent);
endfunction

function void dut_driver::build_phase(uvm_phase phase);
    progress_bar_h = new("progress_bar_h", this);

    // connect to dut interface
    if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_vif", dut_vif))
        `uvm_fatal("NOVIF", "Unable to get 'dut_vif' from config db}")
endfunction

task dut_driver::run_phase(uvm_phase phase);
    forever
        begin
            t_dut_txn txn;
            seq_item_port.try_next_item(txn);  // check whether we have txn to transmitt

            // generate 'vector of enables'(including 'valid' signal for  'DUT output') using randomly-genertaed 'dxi_valid/ready'
            do
                begin
                    @(posedge dut_vif.clk);
                    #p_tco // flipflop update gap(to avoid race condition)

                    // generate 'dxi valid/ready' signals
                    if (null == txn)  // there is no input txn
                        begin
                            dxi_valid = 1'b0;
                        end
                    else
                        begin
                            assert ( std::randomize(dxi_valid) with { dxi_valid dist {1'b1:= p_dxi_dist, 1'b0:= 100-p_dxi_dist}; } );
                        end
                    assert ( std::randomize(dxi_ready) with { dxi_ready dist {1'b1:= p_dxi_dist, 1'b0:= 100-p_dxi_dist}; } );

                    if ( dxi_ready )
                        begin
                            for (int i = p_pipeline; i > 0; i--)
                                begin
                                    ena_vec[i] = ena_vec[i-1];
                                end
                            ena_vec[0] = dxi_valid;
                        end

                    for (int i = 0; i < p_pipeline; i++)
                        begin
                            dut_vif.i_ENA_VEC[i] = ena_vec[i] & dxi_ready;
                        end
                        dut_vif.OUTPUT_VALID = ena_vec[p_pipeline] & dxi_ready;  // 'DUT output' 'valid' signal
                end
            while (!( (1'b1 == dxi_valid && 1'b1 == dxi_ready) || (null == txn) ));  // till transmitt control signals(valif/ready) for txn (if exists) will be active

            // apply existing txn to vif
            if (null != txn)
                begin
                    txn.write(dut_vif);
                    seq_item_port.item_done();
                    progress_bar_h.display();
                    // `uvm_info("dut_driver: dut in content", txn.sprint(), UVM_HIGH)
                end
        end
endtask
