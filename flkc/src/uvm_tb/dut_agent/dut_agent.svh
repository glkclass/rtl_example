class dut_agent #(type t_dut_txn = dut_txn_base) extends uvm_agent;
    `uvm_component_param_utils(dut_agent #(t_dut_txn))

    uvm_analysis_port #(t_dut_txn) monitor_aport;

    dut_agent_cfg dut_agent_cfg_h;
    dut_driver #(t_dut_txn) dut_driver_h;
    dut_monitor #(t_dut_txn) dut_monitor_h;
    uvm_sequencer #(t_dut_txn) dut_sequencer_h;

    extern function new(string name = "dut_agent", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
endclass

function dut_agent::new(string name = "dut_agent", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void dut_agent::build_phase(uvm_phase phase);
    if (!uvm_config_db #(dut_agent_cfg)::get(this, "", "dut_agent_cfg", dut_agent_cfg_h))
        `uvm_fatal("dut_agent", "Unable to get 'dut_agent_cfg' from config db}")

    uvm_config_db #(virtual dut_if)::set(this, "*", "dut_vif", dut_agent_cfg_h.dut_vif);

    if (dut_agent_cfg_h.has_monitor)
        begin
            monitor_aport = new ("monitor_aport", this);
            dut_monitor_h = dut_monitor #(t_dut_txn)::type_id::create("dut_monitor_h", this);
        end

    if (UVM_ACTIVE == dut_agent_cfg_h.is_active)
        begin
            dut_driver_h = dut_driver #(t_dut_txn)::type_id::create("dut_driver_h", this);
            dut_sequencer_h = uvm_sequencer #(t_dut_txn)::type_id::create("dut_sequencer_h", this);
        end
endfunction

function void dut_agent::connect_phase(uvm_phase phase);
    if (UVM_ACTIVE == dut_agent_cfg_h.is_active)
        begin
            dut_driver_h.seq_item_port.connect(dut_sequencer_h.seq_item_export);
        end

    if (dut_agent_cfg_h.has_monitor)
        begin
            dut_monitor_h.aport.connect(monitor_aport);
        end
endfunction
