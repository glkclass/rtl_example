module SM_RAM (i_RSTn, i_CLK, i_WE, i_ADDRESS, i_DATA_IN, o_DATA_OUT);
  parameter   ADDR_WIDTH = 6;
  parameter   DATA_WIDTH = 16;

  input                     i_RSTn, i_CLK, i_WE;
  input   [ADDR_WIDTH-1:0]  i_ADDRESS;
  input   [DATA_WIDTH-1:0]  i_DATA_IN;
  output  [DATA_WIDTH-1:0]  o_DATA_OUT;

integer i;
reg [DATA_WIDTH-1:0] ram [(1<<ADDR_WIDTH)-1:0];



always @(posedge i_CLK, negedge i_RSTn)
begin
    if (!i_RSTn )
        for (i=0; i<(1<<ADDR_WIDTH); i=i+1)
        //ram[i] = 32'h_DEAD_DEAD;
            ram[i] <= 0;

    else if (i_WE)
        ram[i_ADDRESS] <= i_DATA_IN;

end

assign o_DATA_OUT = ram[i_ADDRESS];

endmodule






 