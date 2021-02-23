class dut_env_cfg extends uvm_object;
    `uvm_object_utils(dut_env_cfg)

    bit has_dut_in_agent = 1'b1;
    bit has_dut_out_agent = 1'b1;
    bit has_dut_tp_agent = 1'b1;
    bit has_dut_scb = 1'b1;

    dut_agent_cfg dut_in_agent_cfg_h;
    dut_agent_cfg dut_out_agent_cfg_h;
    dut_agent_cfg dut_tp_agent_cfg_h;
    dut_scb_cfg dut_scb_cfg_h;

    extern function new(string name = "dut_env_cfg");
endclass


function dut_env_cfg::new(string name = "dut_env_cfg");
    super.new(name);
endfunction
