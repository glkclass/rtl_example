class dut_report_server extends uvm_default_report_server;
    `uvm_object_utils(dut_report_server)
    string report_format_str[string];

    extern function new(string name = "dut_report_server");

    extern virtual function string compose_report_message (
        uvm_report_message report_message,
        string report_object_name = "" );

    // reduce 'long hierarchical name'
    extern function string remove_hier_path (
        string s,  // long hierarchical name to be reduced
        string delimiter_list[],  // list of delimiter symbols: "/", "\\", ".", etc
        int nesting_level );  // '0' - return full path, 'n' - return path containing 'n' nesting items

    // read 'field width' parameters and init 'format strings'
    extern function void init_report_format_str();

endclass

function dut_report_server::new(string name = "dut_report_server");
    super.new(name);
    init_report_format_str();
    uvm_default_report_server::set_server( this );//substitute default report server

    // show_verbosity = 1'b1;
    // show_terminator = 1'b1;
endfunction

function string dut_report_server::compose_report_message(uvm_report_message report_message, string report_object_name = "");
    string sev_string;
    uvm_severity l_severity;
    uvm_verbosity l_verbosity;
    string filename_line_string;
    string time_str;
    string line_str;
    string context_str;
    string verbosity_str, verbosity_str_0;
    string terminator_str;
    string msg_body_str;
    uvm_report_message_element_container el_container;
    string prefix;
    uvm_report_handler l_report_handler;

    l_severity = report_message.get_severity();
    sev_string = l_severity.name();

    if ($cast(l_verbosity, report_message.get_verbosity()))
        begin
            verbosity_str_0 = l_verbosity.name();
        end
    else
        begin
            verbosity_str_0.itoa(report_message.get_verbosity());
        end

    if ("UVM_INFO" == sev_string)
        begin
            sev_string = {verbosity_str_0, "_INFO"};
        end

    if (report_message.get_filename() != "")
        begin
            line_str.itoa(report_message.get_line());
            filename_line_string = {report_message.get_filename(), "(", line_str, ")"};
        end

    // Make definable in terms of units.
    // $swrite(time_str, "%0t", $time);

    if (report_message.get_context() != "")
        context_str = {"@@", report_message.get_context()};

    if (show_verbosity)
        begin
            if ($cast(l_verbosity, report_message.get_verbosity()))
                verbosity_str = l_verbosity.name();
            else
                verbosity_str.itoa(report_message.get_verbosity());
            verbosity_str = {"(", verbosity_str, ")"};
        end

    if (show_terminator)
        terminator_str = {" -",sev_string};

    el_container = report_message.get_element_container();
    if (el_container.size() == 0)
        msg_body_str = report_message.get_message();
    else
        begin
            prefix = uvm_default_printer.knobs.prefix;
            uvm_default_printer.knobs.prefix = " +";
            msg_body_str = {report_message.get_message(), "\n", el_container.sprint()};
            uvm_default_printer.knobs.prefix = prefix;
        end

    if (report_object_name == "")
        begin
            l_report_handler = report_message.get_report_handler();
            report_object_name = l_report_handler.get_full_name();
        end

    compose_report_message =
        {
            $sformatf(report_format_str["severity"], sev_string), " |",
            " @ ", $sformatf(report_format_str["time"], $time), " |",
            " ", $sformatf(report_format_str["filename"], remove_hier_path(filename_line_string, '{"/", "\\"}, p_rpt_msg_filename_nesting_level)), " |",
            " ", $sformatf(report_format_str["objectname"], remove_hier_path(report_object_name, '{"."}, p_rpt_msg_objectname_nesting_level)), " |",
            context_str,
            " [", $sformatf(report_format_str["id"], report_message.get_id()), "] ",
            msg_body_str,
            terminator_str
        };

    // compose_report_message = {sev_string, verbosity_str, " ", filename_line_string, "@ ",
    //   time_str, ": ", report_object_name, context_str,
    //   " [", report_message.get_id(), "] ", msg_body_str, terminator_str};
endfunction


function string dut_report_server::remove_hier_path(string s, string delimiter_list[], int nesting_level);
    int last_char_idx;
    int slash_position = -1;
    int n = 0;

    if (0 == nesting_level)
        begin
            return( s );
        end

    last_char_idx = s.len()-1;
    for (int i = last_char_idx; i >= 0; i--)
        begin
            if (s.getc(i) inside {delimiter_list} && (nesting_level == ++n))
                begin
                    slash_position = i;
                    break;
                end
        end
    return( s.substr(slash_position+1, last_char_idx) );
endfunction


function void dut_report_server::init_report_format_str();
    string field_width;

    field_width.itoa(p_rpt_msg_severity_width);
    report_format_str["severity"] = {"\%-", field_width, "s"};

    field_width.itoa(p_rpt_msg_time_width);
    report_format_str["time"] = {"\%-", field_width, "t"};

    field_width.itoa(p_rpt_msg_filename_width);
    report_format_str["filename"] = {"\%-", field_width, "s"};

    field_width.itoa(p_rpt_msg_objectname_width);
    report_format_str["objectname"] = {"\%-", field_width, "s"};

    field_width.itoa(p_rpt_msg_id_width);
    report_format_str["id"] = {"\%-", field_width, "s"};
endfunction













