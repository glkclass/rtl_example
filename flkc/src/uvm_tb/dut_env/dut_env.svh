class dut_env extends uvm_env;
    `uvm_component_utils(dut_env)

    dut_env_cfg dut_env_cfg_h;
    dut_agent #(dut_in_txn) dut_in_agent_h;
    dut_agent #(dut_out_txn) dut_out_agent_h;
    dut_agent #(dut_tp_txn) dut_tp_agent_h;
    dut_scb dut_scb_h;
    uvm_barrier synch_seq_br_h;

    extern function new(string name = "dut_env", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass


function dut_env::new(string name = "dut_env", uvm_component parent = null);
    super.new(name, parent);
    synch_seq_br_h = new ("synch_seq_br_h", 2);
endfunction


function void dut_env::build_phase(uvm_phase phase);
    super.build_phase(phase);

    // extract env config
    if (!uvm_config_db #(dut_env_cfg)::get(this, "", "dut_env_cfg", dut_env_cfg_h))
        `uvm_fatal("dut_env", "Unable to get 'dut_env_cfg' from config db")

    // check whether dut_in agent is present and create it if so
    if (dut_env_cfg_h.has_dut_in_agent)
        begin
            dut_in_agent_h = dut_agent #(dut_in_txn)::type_id::create("dut_in_agent_h", this);
            uvm_config_db #(dut_agent_cfg)::set(this, "dut_in_agent_h*", "dut_agent_cfg", dut_env_cfg_h.dut_in_agent_cfg_h);
            uvm_config_db #(uvm_barrier)::set(this, "dut_in_agent_h*", "synch_seq_barrier", synch_seq_br_h);
        end

    // check whether dut_out agent is present and create it if so
    if (dut_env_cfg_h.has_dut_out_agent)
        begin
            dut_out_agent_h = dut_agent #(dut_out_txn)::type_id::create("dut_out_agent_h", this);
            uvm_config_db #(dut_agent_cfg)::set(this, "dut_out_agent_h*", "dut_agent_cfg", dut_env_cfg_h.dut_out_agent_cfg_h);
        end

    // check whether dut_tp agent is present and create it if so
    if (dut_env_cfg_h.has_dut_tp_agent)
        begin
            dut_tp_agent_h = dut_agent #(dut_tp_txn)::type_id::create("dut_tp_agent_h", this);
            dut_monitor #(dut_tp_txn)::type_id::set_type_override(dut_tp_monitor #(dut_tp_txn)::get_type());

            uvm_config_db #(dut_agent_cfg)::set(this, "dut_tp_agent_h*", "dut_agent_cfg", dut_env_cfg_h.dut_tp_agent_cfg_h);
        end

    // check whether scoreboard is present and create it if so
    if (dut_env_cfg_h.has_dut_scb)
        begin
            dut_scb_h = dut_scb::type_id::create("dut_scb_h", this);
            uvm_config_db #(dut_scb_cfg)::set(this, "dut_scb_h*", "dut_scb_cfg", dut_env_cfg_h.dut_scb_cfg_h);
            uvm_config_db #(uvm_barrier)::set(this, "dut_scb_h*", "synch_seq_barrier", synch_seq_br_h);
        end
endfunction


function void dut_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // connect 'dut_in' agent output to scoreboard 'dut_in' input port if required
    if (dut_env_cfg_h.has_dut_scb & dut_env_cfg_h.has_dut_in_agent)
        begin
            if (
                 dut_env_cfg_h.dut_in_agent_cfg_h.has_monitor &
                 (dut_env_cfg_h.dut_scb_cfg_h.has_coverage_collector | dut_env_cfg_h.dut_scb_cfg_h.has_predictor)
                )
                begin
                    dut_in_agent_h.monitor_aport.connect(dut_scb_h.dut_in_export);
                end
        end

    // connect 'dut_out' agent output to scoreboard 'dut_out' input port if required
    if (dut_env_cfg_h.has_dut_scb & dut_env_cfg_h.has_dut_out_agent)
        begin
            if (dut_env_cfg_h.dut_out_agent_cfg_h.has_monitor & dut_env_cfg_h.dut_scb_cfg_h.has_evaluator)
                begin
                    dut_out_agent_h.monitor_aport.connect(dut_scb_h.dut_out_export);
                end
        end

    // connect 'dut_tp' agent output to scoreboard 'dut_tp' input port if required
    if (dut_env_cfg_h.has_dut_scb & dut_env_cfg_h.has_dut_tp_agent)
        begin
            if (dut_env_cfg_h.dut_tp_agent_cfg_h.has_monitor & dut_env_cfg_h.dut_scb_cfg_h.has_evaluator)
                begin
                    dut_tp_agent_h.monitor_aport.connect(dut_scb_h.dut_tp_export);
                end
        end

endfunction





