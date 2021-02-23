class dut_test_base extends uvm_test;
    `uvm_component_utils(dut_test_base)

    virtual dut_if dut_vif;

    dut_env_cfg dut_env_cfg_h;
    dut_agent_cfg dut_in_agent_cfg_h;
    dut_agent_cfg dut_out_agent_cfg_h;
    dut_agent_cfg dut_tp_agent_cfg_h;
    dut_scb_cfg dut_scb_cfg_h;

    dut_env dut_env_h;

    dut_handler dut_handler_h;

    extern function new(string name = "dut_test", uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern function void start_of_simulation();
    extern task run_phase(uvm_phase phase);
endclass

function dut_test_base::new(string name = "dut_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void dut_test_base::start_of_simulation();
    // replace 'default report server' with customized version
    dut_report_server dut_report_server_h = new ("dut_report_server_h");
    super.start_of_simulation();
endfunction

function void dut_test_base::build_phase(uvm_phase phase);
    dut_handler_h = new ("dut_handler_h", this);
    uvm_config_db #(dut_handler)::set(this, "*", "dut_handler", dut_handler_h);

    // extract dut virtual if from db
    if (!uvm_config_db #(virtual dut_if)::get(this, "", "dut_if", dut_vif))
        `uvm_fatal("CFG_DB_ERROR", "Unable to get \"dut_if\" from config db")

    // create dut_in agent config
    dut_in_agent_cfg_h = dut_agent_cfg::type_id::create("dut_in_agent_cfg_h", this);
    dut_in_agent_cfg_h.dut_vif = dut_vif;

    // create dut_out agent config
    dut_out_agent_cfg_h = dut_agent_cfg::type_id::create("dut_out_agent_cfg_h", this);
    dut_out_agent_cfg_h.dut_vif = dut_vif;
    dut_out_agent_cfg_h.is_active = UVM_PASSIVE;

    // create dut_out agent config
    dut_tp_agent_cfg_h = dut_agent_cfg::type_id::create("dut_tp_agent_cfg_h", this);
    dut_tp_agent_cfg_h.dut_vif = dut_vif;
    dut_tp_agent_cfg_h.is_active = UVM_PASSIVE;

    // create scb config
    dut_scb_cfg_h = dut_scb_cfg::type_id::create("dut_scb_cfg_h", this);

    // create env config
    dut_env_cfg_h = dut_env_cfg::type_id::create("dut_env_cfg_h", this);

    // init 'agent config' handles located inside 'env config'
    dut_env_cfg_h.dut_in_agent_cfg_h = dut_in_agent_cfg_h;
    dut_env_cfg_h.dut_out_agent_cfg_h = dut_out_agent_cfg_h;
    dut_env_cfg_h.dut_tp_agent_cfg_h = dut_tp_agent_cfg_h;

    // init 'scoreboard config' handle locate inside 'env config'
    dut_env_cfg_h.dut_scb_cfg_h = dut_scb_cfg_h;

    // save 'env config' handle to db
    uvm_config_db #(dut_env_cfg)::set(this, "dut_env_h*", "dut_env_cfg", dut_env_cfg_h);

    // create env
    dut_env_h = dut_env::type_id::create("dut_env_h", this);
endfunction


task dut_test_base::run_phase(uvm_phase phase);
endtask

