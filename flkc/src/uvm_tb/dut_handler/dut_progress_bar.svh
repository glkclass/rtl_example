// class to display 'progress bar'. Can be instantiated in the any uvm_component and used to 'log information' about progress (num of txn, checks, statistics, ...)
class dut_progress_bar #(parameter uvm_verbosity p_uvm_verbosity = UVM_HIGH) extends uvm_component;
    // `uvm_component_utils(dut_progress_bar)

    int cnt;
    uvm_verbosity verbosity;
    extern function new(string name = "dut_progress_bar", uvm_component parent=null);
    extern function void display (string message = "");
endclass


function dut_progress_bar::new(string name = "dut_progress_bar", uvm_component parent=null);
    super.new(name, parent);
    verbosity = p_uvm_verbosity;
    cnt = 0;
endfunction


// display 'progress bar' information
function void dut_progress_bar::display (string message="");
    if (p_milestone_length > 0)
        begin
            cnt++;
            if (0 == cnt%p_milestone_length)
                begin
                    `uvm_info("PROGRESS", {$sformatf("%0d... ", cnt), message}, verbosity)
                end
        end
endfunction




