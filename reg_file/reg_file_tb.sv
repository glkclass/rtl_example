
`timescale 1 ns / 1 ps

//sm_tm module. Generates reset, clk siganls. Reads input test vectors from file and
module SM_TB
    #(
        parameter
        ADDR_WIDTH = 7,
        DATA_WIDTH = 21,
        RESULT_WIDTH = 16,
        TV_IN_FN = "..\\tests\\the_code.in"             // Input test vector file.
        //RES_OUT_FN = "..\\tests\\results.out")        // Output results.
    )

    (
        input                       i_RDY,
                                    i_ERROR,
                [RESULT_WIDTH-1:0]  i_RESULT,

        output                      o_RSTn,
                                    o_CLK,
                                    o_WE,
                [ADDR_WIDTH-1:0]    o_ADDRESS,
                [DATA_WIDTH-1:0]    o_DATA
    );


    localparam OP_WIDTH = RESULT_WIDTH;
    localparam OP_ADDR_WIDTH = ADDR_WIDTH-1;
    localparam OP_COD_WIDTH = 3;

    localparam CLK_PERIOD = 100;
    localparam RST_INTERVAL = 220;

    localparam NOP_OP_CODE = 3'b000;
    localparam ADD_OP_CODE = 3'b001;
    localparam SUB_OP_CODE = 3'b010;
    localparam MUL_OP_CODE = 3'b011;
    localparam END_OP_CODE = 3'b111;



event load_next_program, program_finished, verification_finished;

integer fin, result, ref_result, error;

reg rst=0, clk, we;
reg [ADDR_WIDTH-1:0] address;
reg [DATA_WIDTH-1:0] data;




// function converts instruction mnemonic to opcode
function integer get_opcode;
    input string instr;
    integer op_code;

    case (instr)
        "ADD":  op_code = ADD_OP_CODE;
        "SUB":  op_code = SUB_OP_CODE;
        "MUL":  op_code = MUL_OP_CODE;
        "NOP":  op_code = NOP_OP_CODE;
        "END":  op_code = END_OP_CODE;
        default:;
    endcase
    get_opcode = op_code;

endfunction


// tasks definitions
// read_commands reads input commands/data from txt file, loads them to UUT, initiates program execution and compares results.
task    load_program;

    parameter INSTR_WE = 1'b0;
    parameter DATA_WE = 1'b1;

    integer i, pc;
    string instr;

    reg [OP_COD_WIDTH-1:0] op_code;
    reg [OP_ADDR_WIDTH-1:0] op_addr[3];
    reg [OP_ADDR_WIDTH-1:0] data_addr;
    reg [OP_WIDTH-1:0] data_val;

    fin = $fopen (TV_IN_FN, "r");

    if (!fin) begin
        $display ("%t: Failed to open input test vector %s.", $time, TV_IN_FN);
        $stop(2);
    end


    while ( !$feof(fin) ) begin
        @( load_next_program );

        $display("%t: Loading program from %s ...", $time, TV_IN_FN);

        pc = -1;
        instr = "";
        //every input program is ended with "$$$""
        while ( instr.compare("$$$") != 0  && !$feof(fin) ) begin
            @(posedge clk)      //wait for clk edge

            pc++;   //increment program counter


            //read command and then read various number of operands depending on command type (instruction load/data load/wait for execution result)
            $fscanf(fin, "%s", instr);  //read instruction and then read various number of operands depending on instruction type
            case (instr)
                "ADD", "SUB", "MUL":
                    $fscanf(fin, "%d %d %d", op_addr[0], op_addr[1], op_addr[2]);

                "DAT":
                    $fscanf(fin, "%d %d", data_addr, data_val);

                "$$$":
                    $fscanf(fin, "%d", ref_result);

                default:;
            endcase

            //force output signal to code/data memory
            case (instr)
                "ADD", "SUB", "MUL": begin
                    op_code = get_opcode(instr);    //convert instruction mnemonic to opcode
                    data = {op_code, op_addr[0], op_addr[1], op_addr[2]};   //21= 3+6+6+6
                    address = {INSTR_WE, pc};   //7 = 1+6
                    we = 1; //enable program/data memory load
                end

                "NOP", "END": begin
                    op_code = get_opcode(instr);    //convert instruction mnemonic to opcode
                    for (i=0; i<3; i++)
                        op_addr[i]=0;
                    data = {op_code, op_addr[0], op_addr[1], op_addr[2]};   //21= 3+6+6+6
                    address = {INSTR_WE, pc};   //7 = 1+6
                    we = 1; //enable program/data memory load
                end


                "DAT": begin
                    data = data_val;    //high 6 bits left unconnected
                    address = {DATA_WE, data_addr}; //7=1+6
                    we = 1; //enable program/data memory load
                end

                "$$$":
                    we = 0; //disable program/data memory load

                default:;
            endcase
        end//while
        if ( instr.compare("$$$") == 0 ) begin
            $display("%t: Successfuly loaded.", $time);
        end
    end//while

    $display("%t: Input TV %s is out.", $time, TV_IN_FN);
    $fclose(fin);
    -> verification_finished;

endtask
//End of task definitions


// compare reference result read from the input file and real result of program execution
task    check_result;
    //input                       error = 0;
    //input  [RESULT_WIDTH-1:0]   result = 0;
    //input  integer              ref_result = 0;
    static integer verification_is_finished = 0;

    while (!verification_is_finished) begin
        @(program_finished, verification_finished)

        if (!verification_finished.triggered) begin
            result = $signed(i_RESULT);
            error = $unsigned(i_ERROR);

            if ( (error != 1) && (result == ref_result) )
                $display ("%t: Test passed. Error = %d, result = %d, ref_result = %d.\n", $time, error, result, ref_result);
            else
                $display ("%t: Test failed. Error = %d, result = %d, ref_result = %d.\n", $time, error, result, ref_result);
        end//if
        else
            verification_is_finished = 1;

    end//while
endtask




assign o_RSTn = rst;
assign o_CLK = clk;
assign o_WE = we;
assign o_ADDRESS = address;
assign o_DATA = data;


//the very first program start
initial forever begin
    @(posedge rst );
        -> load_next_program;
end


//program finished -> check results
initial forever begin
    @(posedge i_RDY );
        -> program_finished;
end


// next program starts
initial forever begin
    @(negedge i_RDY );
    if (rst)
        -> load_next_program;
end





// rst signal generation
initial begin
    we = 1'b0;
    rst = 1'b0;
    #(RST_INTERVAL )rst = 1'b1;
end

// clk generation
initial begin
    clk = 1'b0;
    forever
        #(CLK_PERIOD/2) clk = ~clk;
end


//load program and check execution results
initial begin
    fork
        load_program; //(address, data, we, ref_result); //load program
        check_result; //(error, result, ref_result); //check execution result
    join

    $display ("%t: Verification is finished\n", $time);
    //$stop(2);
    $finish(2);
end







endmodule
