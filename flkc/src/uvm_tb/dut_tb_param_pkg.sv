package dut_tb_param_pkg;
    parameter
    //tb params
    p_clk_period  = 10, // single clk cycle duration
    p_rstn_period  = 33, // rst signal duration
    p_tco  = 1, // 'update gap' (to avoid race conditions)
    p_max_fail_num  = 16, // max number of failed transactions after which TB will be stopped
    p_dxi_dist  = 20, // percentage of 'active' dxi transactions
    p_milestone_length  = 10, // number of processed items to be reported as 'milestone' passed. To be used in 'progress bar'.
    p_log_buffer_size = 1, // size of DPI log buffer

    //'report server' message(UVM_INFO/WARNING/ERROR/FATAL) field widths
    p_rpt_msg_severity_width = 15,
    p_rpt_msg_time_width = 6,
    p_rpt_msg_filename_width = 30,
    p_rpt_msg_objectname_width = 30,
    p_rpt_msg_id_width = 12,
    p_rpt_msg_filename_nesting_level = 1,  // define 'filename max nesting level'. '0' - 'display full hierarchial name'
    p_rpt_msg_objectname_nesting_level = 2;  // define 'objectname max nesting level'. '0' - 'display full hierarchial path'
endpackage

