
//sm_core module. Contains main core implementation.
module SM_CORE
    #(
    parameter
        CODERAM_ADDR_WIDTH = 6,
        CODERAM_DATA_WIDTH = 21,
        DATARAM_ADDR_WIDTH = 6,
        DATARAM_DATA_WIDTH = 16,
        RESULT_WIDTH = 16
    )
    (
        //inputs/outputs

        //TB interface
        input                               i_RSTn, i_CLK, i_TB_WE,
        output                              o_RDY, o_ERROR,
                [RESULT_WIDTH-1:0]          o_RESULT,

        //CODE RAM interface
        input   [CODERAM_DATA_WIDTH-1:0]    i_CODERAM_DATA,
        output  [CODERAM_ADDR_WIDTH-1:0]    o_CODERAM_ADDR,


        //DATA RAM interface
        input   [DATARAM_DATA_WIDTH-1:0]    i_DATARAM_DATA,
        output                              o_DATARAM_WE,
                [DATARAM_ADDR_WIDTH-1:0]    o_DATARAM_ADDR,
                [DATARAM_DATA_WIDTH-1:0]    o_DATARAM_DATA



    );




    localparam  FSM_WIDTH   = 3;  //width of FSM state

    //intruction opcodes. Have to be aligned with testbench matches.
    localparam NOP_OP_CODE  = 3'b000;
    localparam ADD_OP_CODE  = 3'b001;
    localparam SUB_OP_CODE  = 3'b010;
    localparam MUL_OP_CODE  = 3'b011;
    localparam END_OP_CODE  = 3'b111;

    //16 bits MAX/ MIN consts
    localparam MAX_16   = 16'h7FFF;
    localparam MIN_16   = 16'h8000;




typedef enum reg [FSM_WIDTH-1:0] {_IDLE, _INIT, _RUN, _RD_STALL, _WR_STALL, _WR_RD_STALL, _FINISH} FSM_STATES;
FSM_STATES pr_state, next_state;

reg  rdy;
reg  c_we, d_we;
reg  [CODERAM_DATA_WIDTH-1:0] c_data_rd, instr;
reg  [RESULT_WIDTH-1:0] d_data_rd, result;
reg  [CODERAM_ADDR_WIDTH-1:0] pc;
reg  [DATARAM_ADDR_WIDTH-1:0] d_addr;
reg  run, rd_first_op, stall_ex, error;
reg  s_end, finish, rd_stall, wr_stall, wr_result, stall;
reg  op0_mem, op1_mem;
reg  op0_mem_dr, op1_mem_dr;
reg  op0_mem_ex, op1_mem_ex;
reg  mult_overflow, add_overflow, sub_overflow, overflow=0;
reg  [3:0] select_op_addr;
reg  [1:0] pc_cntrl;
reg  [2:0] op_code_dr, op_code_ex;
reg  [5:0] op_addr;
reg  [5:0] op0_addr_dr, op1_addr_dr;
reg  [5:0] op2_addr_dr, op2_addr_ex, op2_addr_st;

reg  [RESULT_WIDTH-1:0] op0_data_ex, op1_data_ex;
reg  signed [RESULT_WIDTH-1:0] op0_data_alu, op1_data_alu;
wire signed [RESULT_WIDTH:0] op0_data_alu_0, op1_data_alu_0;
reg  [RESULT_WIDTH:0] add, sub;
reg  [2*RESULT_WIDTH-1:0] mult;
reg  [RESULT_WIDTH:0] alu_result;

wire [2:0]  op_code;
wire [DATARAM_ADDR_WIDTH-1:0] op0_addr, op1_addr, op2_addr;


reg [1:0] dbg;



//ports
//TB interface
assign o_RDY = rdy;
assign o_ERROR = error;
assign o_RESULT = result;

//CODERAM interface
assign o_CODERAM_ADDR = pc;
assign c_data_rd = i_CODERAM_DATA;

//DATARAM interface
assign o_DATARAM_WE = wr_result;
assign o_DATARAM_ADDR = op_addr;
assign o_DATARAM_DATA = alu_result;
assign d_data_rd = i_DATARAM_DATA;

//aliases
assign   op_code = instr[20:18];
assign   op0_addr = instr[17:12];
assign   op1_addr = instr[11:6];
assign   op2_addr = instr[5:0];



//FSM comb
always @ (pr_state, i_TB_WE, s_end, wr_stall, rd_stall ) begin
    case(pr_state)
        _IDLE:  begin
                    if (i_TB_WE == 1)
                        next_state = _INIT;
                    else
                        next_state = _IDLE;
                    //outputs
                    run             =  0;
                    rd_first_op     =  0;
                    wr_result       =  0;
                    finish          =  0;
                end

        _INIT:  begin
                    if (i_TB_WE == 0)
                        next_state = _RUN;
                    else
                        next_state = _INIT;
                    //outputs
                    run             =  0;
                    rd_first_op     =  0;
                    wr_result       =  0;
                    finish          =  0;
                end

        _RUN:   begin
                    if (s_end == 1)
                        next_state    =  _FINISH;
                    else if  (wr_stall == 1 && rd_stall == 0)
                        next_state    =  _WR_STALL;
                    else if (wr_stall == 0 && rd_stall == 1)
                        next_state    =  _RD_STALL;
                    else if (wr_stall == 1 && rd_stall == 1)
                        next_state    =  _WR_RD_STALL;
                    else
                        next_state    =  _RUN;
                    //outputs
                    run             =  1;
                    rd_first_op     =  0;
                    wr_result       =  0;
                    finish          =  0;
                end

        _WR_STALL:   begin
                        if (s_end == 1)
                            next_state    =  _FINISH;
                        else
                            next_state    =  _RUN;
                        //outputs
                        run               =  1;
                        rd_first_op       =  0;
                        wr_result         =  1;
                        finish            =  0;
                    end

        _RD_STALL:   begin
                        if (s_end == 1)
                            next_state    =  _FINISH;
                        else
                            next_state    =  _RUN;
                        //outputs
                        run               =  1;
                        rd_first_op       =  1;
                        wr_result         =  0;
                        finish            =  0;
                    end


        _WR_RD_STALL:    begin
                            if (s_end == 1)
                                next_state    =  _FINISH;
                            else
                                next_state    =  _RD_STALL;
                            //outputs
                            run               =  1;
                            rd_first_op       =  0;
                            wr_result         =  1;
                            finish            =  0;
                        end

        _FINISH: begin
                    next_state      =  _IDLE;
                    //outputs
                    run             =  0;
                    rd_first_op     =  0;
                    wr_result       =  0;
                    finish          =  1;
                end


        default:    begin
                        next_state    =  _IDLE;
                        //outputs
                        run           =  0;
                        rd_first_op   =  0;
                        wr_result     =  0;
                        finish        =  0;
                    end
    endcase
 end


// read or write stall cycle
assign stall  = wr_result | rd_first_op;

// run pc when durinng execution, stop pc during stall cycles
assign pc_cntrl  =  {run, stall};




//FSM synch
always @ (posedge i_CLK, negedge i_RSTn) begin
    if (!i_RSTn)
        pr_state <=  _IDLE;
    else
        pr_state <=  next_state;
end




//program counter and read instruction
always @ (posedge i_CLK , negedge i_RSTn) begin
    if (!i_RSTn) begin
        pc      <=  0;
        instr   <=  0;
    end
    else
        case (pc_cntrl)
            2'b10:  begin
                pc 		<= pc+1;               //program counter during execution stage
                instr   <= c_data_rd;
            end

            2'b11:  begin
                pc      <= pc;      //program counter during stall cycles
                instr   <= instr;
            end

            default:    begin
                pc      <= 0;       //program counter during non execution stage
                instr   <= 0;
            end
        endcase
end //always



//
always @ (posedge i_CLK, negedge i_RSTn) begin
    if (!i_RSTn)
        stall_ex <=  0;
    else
        stall_ex <=  stall;

end



//
always @ (posedge i_CLK , negedge i_RSTn) begin
    if (!i_RSTn) begin
        op_code_dr        <=  0;
        op_code_ex        <=  0;

        op0_mem_dr        <=  0;
        op0_mem_ex        <=  0;

        op1_mem_dr        <=  0;
        op1_mem_ex        <=  0;

        op0_addr_dr       <=  0;
        op1_addr_dr       <=  0;

        op2_addr_dr       <=  0;
        op2_addr_ex       <=  0;
        op2_addr_st       <=  0;
    end
    else
        if (!stall) begin
            op_code_dr            <=  op_code;
            op_code_ex            <=  op_code_dr;

            op0_mem_dr            <=  op0_mem;
            op0_mem_ex            <=  op0_mem_dr;

            op1_mem_dr            <=  op1_mem;
            op1_mem_ex            <=  op1_mem_dr;

            op0_addr_dr           <=  op0_addr;
            op1_addr_dr           <=  op1_addr;

            op2_addr_dr           <=  op2_addr;
            op2_addr_ex           <=  op2_addr_dr;
            op2_addr_st           <=  op2_addr_ex;
        end
        else    begin
            op_code_dr            <=  op_code_dr;
            op_code_ex            <=  op_code_ex;

            op0_mem_dr            <=  op0_mem_dr;
            op0_mem_ex            <=  op0_mem_ex;

            op1_mem_dr            <=  op1_mem_dr;
            op1_mem_ex            <=  op1_mem_ex;

            op0_addr_dr           <=  op0_addr_dr;
            op1_addr_dr           <=  op1_addr_dr;

            op2_addr_dr           <=  op2_addr_dr;
            op2_addr_ex           <=  op2_addr_ex;
            op2_addr_st           <=  op2_addr_st;
        end

end //always



//
always @ (posedge i_CLK , negedge i_RSTn) begin
    if (!i_RSTn) begin
        op0_data_ex       <=  0;
        op1_data_ex       <=  0;
    end
    else
        case (select_op_addr)
            4'b0111, 4'b0001:  begin
                op0_data_ex       <=  d_data_rd;
                op1_data_ex       <=  op1_data_ex;
            end

            4'b0011, 4'b0010:  begin
                op0_data_ex       <=  op0_data_ex;
                op1_data_ex       <=  d_data_rd;
            end

            default:    begin
                op0_data_ex       <=  op0_data_ex;
                op1_data_ex       <=  op1_data_ex;
            end
        endcase
end //always


//
always @ (posedge i_CLK , negedge i_RSTn) begin
    if (!i_RSTn) begin
        alu_result  <=  0;
        overflow    <=  0;
    end
    else
        if (!stall_ex)
            case (op_code_ex)
                ADD_OP_CODE:    begin
                    alu_result   <=  add;
                    overflow     <=  ~error & (overflow | mult_overflow | add_overflow | sub_overflow);
                end

                SUB_OP_CODE:    begin
                    alu_result   <=  sub;
                    overflow     <=  ~error & (overflow | mult_overflow | add_overflow | sub_overflow);
                end

                MUL_OP_CODE:    begin
                    alu_result   <=  mult;
                    overflow     <=  ~error & (overflow | mult_overflow | add_overflow | sub_overflow);
                end

                default:    begin
                    alu_result   <=  alu_result;
                    overflow     <=  ~error & overflow;
                end
            endcase
        else    begin
            alu_result  <=  alu_result;
            overflow    <=  ~ error & overflow;
        end
end //always



//
always @ (posedge i_CLK , negedge i_RSTn) begin
    if (!i_RSTn)
        result  <=  0;
    else
        if (s_end)
            result  <= alu_result;
        else
            result  <= result;
end //always

//
always @ (posedge i_CLK , negedge i_RSTn) begin
    if (!i_RSTn)
        rdy     <=  0;
    else
        rdy     <= finish;

end //always





assign error =  rdy & overflow;
assign s_end = (op_code_ex == END_OP_CODE) ? 1:0;
assign op0_data_alu = (op0_mem_ex == 1) ? op0_data_ex : alu_result;
assign op1_data_alu = (op1_mem_ex == 1) ? op1_data_ex : alu_result;


assign op0_data_alu_0 = $signed(op0_data_alu);
assign op1_data_alu_0 = $signed(op1_data_alu);
assign add = op0_data_alu_0 + op1_data_alu_0;
assign sub = op0_data_alu_0 - op1_data_alu_0;
assign mult = op0_data_alu * op1_data_alu;

assign add_overflow = (add[RESULT_WIDTH] != add[RESULT_WIDTH-1]) ? 1:0;
assign sub_overflow = (sub[RESULT_WIDTH] != sub[RESULT_WIDTH-1]) ? 1:0;
assign mult_overflow = ( ( $signed(mult) > $signed(MAX_16) ) || ( $signed(mult) < $signed(MIN_16) ) ) ? 1:0;

assign op0_mem = ( (op0_addr > 0) ) ? 1:0;
assign op1_mem = ( (op1_addr > 0) ) ? 1:0;


assign wr_stall = (op2_addr_ex > 0) ? 1:0;
assign rd_stall =  op0_mem & op1_mem;


//select operand address: read op0/read op1/write op2
assign select_op_addr = {wr_result, rd_first_op, op1_mem_dr, op0_mem_dr};


always @ ( select_op_addr, op0_addr_dr, op1_addr_dr, op2_addr_st)   begin
    case (select_op_addr)
        4'b0111, 4'b0001:   op_addr     =  op0_addr_dr;
        4'b0011, 4'b0010:   op_addr     =  op1_addr_dr;
        default:            op_addr     =  op2_addr_st;
    endcase
end






endmodule
