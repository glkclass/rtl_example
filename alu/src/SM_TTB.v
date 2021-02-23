//ttb
//sm_ttb module. Top level design containing sm_tb (generates test vectors), sm_ram(ram model) and sm_core(core implementation).
module SM_TTB;

//
//parameter   SIM_TYPE = "FUNC";
//parameter   SIM_TYPE = "GATE";

parameter   TV_IN_FN = "..\\tests\\the_code.in";       // The input test vector file.
//parameter   RES_OUT_FN = "..\\tests\\results.out";     // The output results.

parameter   TESTBENCH_ADDR_WIDTH = 7;
parameter   CODERAM_ADDR_WIDTH = TESTBENCH_ADDR_WIDTH-1;
parameter   DATARAM_ADDR_WIDTH = TESTBENCH_ADDR_WIDTH-1;

parameter   TESTBENCH_DATA_WIDTH = 21;
parameter   CODERAM_DATA_WIDTH = 21;
parameter   DATARAM_DATA_WIDTH = 16;
parameter   RESULT_WIDTH = 16;



//
wire rst, clk, rdy, error;
wire tb_we, coderam_we;
wire [TESTBENCH_ADDR_WIDTH-1:0] tb_addr;
wire [TESTBENCH_DATA_WIDTH-1:0] tb_data;

wire [CODERAM_ADDR_WIDTH-1:0] coderam_addr, core_coderam_addr;
wire [CODERAM_DATA_WIDTH-1:0] coderam_data_in;
wire [CODERAM_DATA_WIDTH-1:0] coderam_data_out;

wire [DATARAM_ADDR_WIDTH-1:0] dataram_addr, core_dataram_addr;
wire [DATARAM_DATA_WIDTH-1:0] dataram_data_in, core_dataram_data_out;
wire [DATARAM_DATA_WIDTH-1:0] dataram_data_out;

wire [RESULT_WIDTH-1:0] result;



//
SM_TB
#(
    .TV_IN_FN (TV_IN_FN),
    //.RES_OUT_FN (RES_OUT_FN),
    .ADDR_WIDTH (TESTBENCH_ADDR_WIDTH),
    .DATA_WIDTH (TESTBENCH_DATA_WIDTH),
    .RESULT_WIDTH (RESULT_WIDTH)
)
TEST_BENCH (
    .i_RDY      (rdy),
    .i_ERROR    (error),
    .i_RESULT   (result),
    .o_RSTn      (rst),
    .o_CLK      (clk),
    .o_WE       (tb_we),
    .o_ADDRESS  (tb_addr),
    .o_DATA     (tb_data)
);




//
SM_CORE
 #(
     .CODERAM_ADDR_WIDTH     (CODERAM_ADDR_WIDTH),
     .DATARAM_ADDR_WIDTH     (DATARAM_ADDR_WIDTH),
     .CODERAM_DATA_WIDTH     (CODERAM_DATA_WIDTH),
     .DATARAM_DATA_WIDTH     (DATARAM_DATA_WIDTH),
     .RESULT_WIDTH           (RESULT_WIDTH)
 )
UUT
(
    //TB interface
    .i_RSTn              (rst),
    .i_CLK              (clk),
    .i_TB_WE            (tb_we),
    .o_RDY              (rdy),
    .o_ERROR            (error),
    .o_RESULT           (result),

    //CODE RAM interface
    .i_CODERAM_DATA     (coderam_data_out),
    .o_CODERAM_ADDR     (core_coderam_addr),


    //DATA RAM interface
    .i_DATARAM_DATA     (dataram_data_out),
    .o_DATARAM_WE      (core_we),
    .o_DATARAM_ADDR     (core_dataram_addr),
    .o_DATARAM_DATA     (core_dataram_data_out)

    );





assign coderam_addr = (tb_we == 1'b1) ? tb_addr : core_coderam_addr;                    //high address bit selects coderam or dataram
assign coderam_data_in = tb_data;
assign coderam_we = tb_we && ~tb_addr[TESTBENCH_ADDR_WIDTH-1];

SM_RAM
#(
    .ADDR_WIDTH (CODERAM_ADDR_WIDTH),
    .DATA_WIDTH (CODERAM_DATA_WIDTH)
)
CODE_RAM (
    .i_RSTn          (rst),
    .i_CLK          (clk),
    .i_WE           (coderam_we),
    .i_ADDRESS      (coderam_addr),
    .i_DATA_IN      (coderam_data_in),
    .o_DATA_OUT     (coderam_data_out)
    );





assign dataram_addr = (tb_we == 1'b1) ? tb_addr : core_dataram_addr;                    //high address bit selects coderam or dataram
assign dataram_data_in = (tb_we == 1'b1) ? tb_data : core_dataram_data_out;             //high address bit selects coderam or dataram
assign dataram_we = core_we | tb_we && tb_addr[TESTBENCH_ADDR_WIDTH-1];                 //

SM_RAM
#(
    .ADDR_WIDTH (DATARAM_ADDR_WIDTH),
    .DATA_WIDTH (DATARAM_DATA_WIDTH)
)
DATA_RAM (
    .i_RSTn          (rst),
    .i_CLK          (clk),
    .i_WE           (dataram_we),
    .i_ADDRESS      (dataram_addr),
    .i_DATA_IN      (dataram_data_in),
    .o_DATA_OUT     (dataram_data_out)
);


endmodule
