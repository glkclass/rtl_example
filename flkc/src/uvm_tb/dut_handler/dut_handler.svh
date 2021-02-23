// class to handle possible fails:
    // store/load transactions to/from 'recorder_db' file.
    // count fails/success
    // stop test when given condition (max number of fails, coverage target achieved, ...) detected
class dut_handler extends uvm_component;
    // `uvm_component_utils(dut_handler)

    int                     n_fails, n_success;

    int                     recorder_db_fid;
    t_recorder_db_mode      recorder_db_mode;
    string                  recorder_db_fn;

    uvm_barrier             stop_test_h;
    uvm_event               stop_test_evnt_h;
    string                  stop_test_info;

    extern function new(string name = "dut_handler", uvm_component parent=null);
    extern task run_phase (uvm_phase phase);
    extern function void report_phase (uvm_phase phase);

    extern function void fopen();
    extern function void fclose();

    extern function void write2db (vector content);
    extern function int read4db (ref vector content);

    extern function void fail(vector txn);
    extern function void success();

    extern task wait_for_stop_test();
    extern function void stop_test(string message);

endclass


function dut_handler::new(string name = "dut_handler", uvm_component parent=null);
    super.new(name, parent);
    stop_test_evnt_h = new ("stop_test_evnt_h");
    stop_test_h = new ("stop_test_h", 2);
    n_fails = 0;
    n_success = 0;
    stop_test_info = "";

    recorder_db_fn = "recorder_db.txt";
    recorder_db_fid = 0;
    recorder_db_mode = IDLE;
endfunction


task dut_handler::run_phase(uvm_phase phase);
    forever
        begin
            stop_test_evnt_h.wait_trigger();  // wait for the 'stop current test' condition
            stop_test_evnt_h.reset();  // reset 'stop current test' flag
            #p_tco

            `uvm_info("STOP TEST", $sformatf("Test was stopped due to \'%s\'", stop_test_info), UVM_HIGH)
            stop_test_h.wait_for();  // stop current test
        end
endtask


function void dut_handler::fopen();

    if (WRITE == recorder_db_mode)  // write txn to 'recorder_db' file
        begin
            recorder_db_fid = $fopen( recorder_db_fn, "w" );
            if (0 == recorder_db_fid)
                begin
                    `uvm_fatal("RECORDER_DB", $sformatf("Can't create 'recorder_db file'('%s')", recorder_db_fn))
                end
            else
                begin
                    `uvm_info("RECORDER_DB", "'Store to recorder_db file is enabled", UVM_HIGH)
                end
        end
    else if (READ == recorder_db_mode) // read txn from 'recorder_db' file
        begin
            recorder_db_fid = $fopen( recorder_db_fn, "r" );
            if (0 == recorder_db_fid)
                begin
                    `uvm_info("RECORDER_DB", $sformatf("'recorder_db file'('%s')is absent", recorder_db_fn), UVM_HIGH)
                end
            else
                begin
                    `uvm_info("RECORDER_DB", "'Read from recorder_db file is enabled", UVM_HIGH)
                end
        end
endfunction


function void dut_handler::fclose();
    if (0 != recorder_db_fid)//'recorder_db file' was opened
        $fclose(recorder_db_fid);//close the file
endfunction


function void dut_handler::write2db(vector content);
    if (WRITE == recorder_db_mode)
        begin
            if (0 == recorder_db_fid)
                begin
                    fopen();  // open 'recorder_db' file
                end

            foreach (content[i])
                begin
                    $fwrite (recorder_db_fid, "%-d", content[i]);
                end
            $fwrite (recorder_db_fid, "\n");
            $fflush (recorder_db_fid);
        end
endfunction


function int dut_handler::read4db(ref vector content);
    int ans = 0;
    if (READ == recorder_db_mode)  // 'recorder_db file' is opened for reading
        begin
            if (0 == recorder_db_fid)
                begin
                    fopen();  // open 'recorder_db' file
                end

            if (0 != recorder_db_fid)  // 'recorder_db' file is opened
                begin
                    foreach (content[i])
                        begin
                            ans = $fscanf (recorder_db_fid, "%d", content[i]);
                            if (1 != ans)
                                begin
                                    return 0;  // error
                                end
                        end
                    return 1;  // success
                end
            else
                begin
                    return 0;  // error
                end
        end
    else  // wrong 'recorder_db_mode'
        begin
            return 0;  // error
        end
endfunction


function void dut_handler::fail(vector txn);
    n_fails++;

    if (WRITE == recorder_db_mode)  // write failed txn to 'recorder_db' file
        begin
            write2db (txn);
        end

    if (n_fails > p_max_fail_num)  // terminate current test due to 'max error number' exceed
        begin
            stop_test("Max number of fails detected");
        end
endfunction


function void dut_handler::success();
    n_success++;
endfunction


function void dut_handler::report_phase (uvm_phase phase);
    fclose();

    if (n_fails > p_max_fail_num)  // terminate current test due to 'max error number' exceed
        begin
            `uvm_error("STOP_TEST", $sformatf("Max number (%0d) of fails was exceeded. Simulation was terminated!", p_max_fail_num))
        end

    if (n_fails > 0)
        begin
            `uvm_error("FINAL_RESLT", $sformatf("Success: %0d. Fails: %0d!!!", n_success, n_fails))
        end
    else
        begin
            `uvm_info("FINAL_RESLT", $sformatf("Success: %0d, Fails: %0d.", n_success, n_fails), UVM_HIGH)
        end
endfunction


task dut_handler::wait_for_stop_test();
    stop_test_h.wait_for();
endtask


function void dut_handler::stop_test(string message);
    stop_test_evnt_h.trigger();  // stop current test
    stop_test_info = message;
endfunction
