// p_k = 14,//image width
// p_ch_num = 2,//number of channels
// p_pipeline = 2,//pipeline depth
// p_foo_gain_bit = 10, // w_gain width
// p_rgb_num = 3, // R, G, B
// p_thres_bayer = 14,  // Reg width
// p_y_gain_sft = 4,  // Reg width
// p_pedestal = 13,  // Reg width
// p_gain_vec = p_rgb_num * p_foo_gain_bit,  // RGB gains width
// p_data = (p_k * p_ch_num) - 1  // DXI data width

interface dut_if
(
    input clk, rstn
);
    import dut_param_pkg::*;

    //
    logic                                   OUTPUT_VALID;  // validates dut output

    //DUT interface
    logic  [p_pipeline-1 : 0]               i_ENA_VEC;  // ppln stages enable signals
    logic  [2-1 : 0]                        i_ARR_TYPE;  // Bayer pattern type
    logic                                   i_Y_LSB;  // even or odd row
    logic  [p_gain_vec_bit - 1 : 0]         i_COEFF_VEC;  // Coefficients for correction (3 x p_dut_gain_bit)
    logic  [p_thres_bayer_bit - 1 : 0]      i_REG_FOO_THRES_BAYER;  // Reg
    logic  [p_y_gain_sft_bit - 1 : 0]       i_REG_FOO_Y_GAIN_SFT;  // Reg
    logic  [p_pedestal_bit - 1 : 0]         i_REG_FOO_PEDESTAL;  // Reg
    logic  [p_data_bit - 1 : 0]             i_PIXELS;  // DXI in
    logic  [p_data_bit - 1 : 0]             o_PIXELS;  // DXI out

    // probes
    logic           [p_foo_gain_bit - 1 : 0]           r_gain_bayer [p_ch_num-1 : 0];
    logic   signed  [p_pixel_x_gain_bit - 1 : 0]        w_pixel_x_gain_scld [p_ch_num-1 : 0];



endinterface
