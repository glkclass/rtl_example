module dut_wrp
(
    interface _if
);

    import dut_param_pkg::*;

    foo_correction
    #(
        .p_k_bit                    ( p_k_bit           ),
        .p_ch_num_bit               ( p_ch_num          ),
        .p_pipeline_num_bit         ( p_pipeline        ),
        .p_foo_gain_bit            ( p_foo_gain_bit   ),
        .p_rgb_num_bit              ( p_rgb_num         ),
        .p_thres_bayer_bit          ( p_thres_bayer_bit ),
        .p_y_gain_sft_bit           ( p_y_gain_sft_bit  ),
        .p_pedestal_bit             ( p_pedestal_bit    )
    )
    DUT
    (
        .i_CLK                      ( _if.clk ),
        .i_RSTn                     ( _if.rstn ),
        .i_ENA_VEC                  ( _if.i_ENA_VEC ),
        .i_ARR_TYPE                 ( _if.i_ARR_TYPE ),
        .i_Y_LSB                    ( _if.i_Y_LSB ),
        .i_COEFF_VEC                ( _if.i_COEFF_VEC ),
        .i_PIXELS                   ( _if.i_PIXELS ),
        .o_PIXELS                   ( _if.o_PIXELS ),
        .i_REG_FOO_THRES_BAYER     ( _if.i_REG_FOO_THRES_BAYER ),
        .i_REG_FOO_Y_GAIN_SFT      ( _if.i_REG_FOO_Y_GAIN_SFT ),
        .i_REG_FOO_PEDESTAL        ( _if.i_REG_FOO_PEDESTAL )
    );

    assign  _if.r_gain_bayer[0] = 0;  // DUT.r_gain_bayer[0];
    assign  _if.r_gain_bayer[1] = 0;  // DUT.r_gain_bayer[1];

endmodule
