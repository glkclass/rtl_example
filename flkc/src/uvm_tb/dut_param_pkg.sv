package dut_param_pkg;
    parameter
    // dut param
    p_k_bit             = 14,//image width
    p_ch_num            = 2,//number of channels
    p_pipeline          = 2,//pipeline depth
    p_foo_gain_bit     = 10, // w_gain width
    p_rgb_num           = 3, // R, G, B
    p_thres_bayer_bit   = 14,  // Reg width
    p_y_gain_sft_bit    = 4,  // Reg width
    p_pedestal_bit      = 13,  // Reg width
    p_gain_vec_bit      = p_rgb_num * p_foo_gain_bit,  // RGB gains width
    p_data_bit          = (p_k_bit * p_ch_num),  // DXI data width

    // dut localparam
    p_pixel_m_pedestal_bit      =   p_k_bit + 1,
    p_pixel_x_gain_bit          =   p_pixel_m_pedestal_bit + p_foo_gain_bit,
    p_pixel_p_pedestal_bit      =   p_pixel_x_gain_bit,

    // max values
    p_y_gain_sft_max    =   2**p_y_gain_sft_bit-1,
    p_thres_bayer_max   =   2**p_thres_bayer_bit-1,
    p_pedestal_max      =   2**p_pedestal_bit-1,
    p_coeff_max         =   2**p_foo_gain_bit-1,
    p_pixel_max         =   2**p_k_bit-1;


endpackage

