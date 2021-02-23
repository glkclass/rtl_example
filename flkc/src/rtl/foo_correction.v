
module FOO_CORRECTION
#(

    parameter
    p_k_bit = 4'd14,//image width
    p_ch_num_bit = 2,//number of channels
    p_pipeline_num_bit = 2'd2,//pipeline depth
    p_foo_gain_bit = 4'd10, // w_gain width
    p_rgb_num_bit = 3, // R, G, B
    p_thres_bayer_bit = 14,
    p_y_gain_sft_bit = 4,
    p_pedestal_bit = 13,
    p_foo_gain_vec_bit = p_rgb_num_bit * p_foo_gain_bit,

    p_ch_num_bit_msb = p_ch_num_bit - 1,
    p_pipeline_msb_bit = p_pipeline_num_bit - 1,
    p_data_msb_bit = (p_k_bit * p_ch_num_bit) - 1,
    p_coeff_vec_msb_bit = p_foo_gain_vec_bit - 1,
    p_thres_bayer_msb_bit = p_thres_bayer_bit - 1,
    p_y_gain_sft_msb_bit = p_y_gain_sft_bit - 1,
    p_pedestal_msb_bit = p_pedestal_bit - 1,
    p_dxi_out_msb_bit = (p_k_bit * p_ch_num_bit) - 1
)
(
    input                                           i_CLK,
    input                                           i_RSTn,
    input           [p_pipeline_msb_bit : 0]        i_ENA_VEC,
    //
    input           [p_ch_num_bit_msb : 0]          i_ARR_TYPE,   //Bayer pattern type
    input                                           i_Y_LSB,      //even or odd row
    input           [p_coeff_vec_msb_bit : 0]       i_COEFF_VEC,  //Coefficients for correction (3 x p_foo_gain_bit)
    //Regs
    input           [p_thres_bayer_msb_bit : 0]     i_REG_FOO_THRES_BAYER,
    input           [p_y_gain_sft_msb_bit : 0]      i_REG_FOO_Y_GAIN_SFT,
    input           [p_pedestal_msb_bit : 0]        i_REG_FOO_PEDESTAL,
    //DXI DATA IN
    input           [p_data_msb_bit : 0]            i_PIXELS,
    //DXI DATA OUT
    output          [p_dxi_out_msb_bit : 0]         o_PIXELS
);

    localparam
    p_pixel_m_pedestal_bit      =   p_k_bit + 1,
    p_pixel_x_gain_bit          =   p_pixel_m_pedestal_bit + p_foo_gain_bit,
    p_pixel_p_pedestal_bit      =   p_pixel_x_gain_bit,
    p_max_b14_bit               =   14'd16383,
    p_min_b14_bit               =   14'd0;


    //
    wire            [p_pedestal_msb_bit : 0]                w_reg_foo_pedestal;


    //
    wire            [p_foo_gain_bit - 1            : 0]    w_gain [p_rgb_num_bit-1 : 0];
    reg             [p_foo_gain_bit - 1            : 0]    r_gain_bayer [p_ch_num_bit_msb : 0];

    wire            [p_k_bit - 1                    : 0]    w_pixel_in [p_ch_num_bit_msb : 0];
    reg             [p_k_bit - 1                    : 0]    r_pixel_in_pp1 [p_ch_num_bit_msb : 0];
    wire    signed  [p_pixel_m_pedestal_bit - 1     : 0]    w_pixel_m_pedestal [p_ch_num_bit_msb : 0];

    wire    signed  [p_pixel_x_gain_bit - 1         : 0]    w_pixel_x_gain [p_ch_num_bit_msb : 0];
    reg     signed  [p_pixel_x_gain_bit - 1         : 0]    r_pixel_x_gain_pp1 [p_ch_num_bit_msb : 0];
    wire    signed  [p_pixel_p_pedestal_bit - 1     : 0]    w_pixel_p_pedestal [p_ch_num_bit_msb : 0];

    wire            [p_pixel_x_gain_bit + 1 - 1     : 0]    w_pixel_x_gain_brl_0st [p_ch_num_bit_msb : 0];//add 1 bit to save low bits for rnd const calculation
    wire            [p_pixel_x_gain_bit + 3 - 1     : 0]    w_pixel_x_gain_brl_1st [p_ch_num_bit_msb : 0];//add 3 bit to save low bits for rnd const calculation
    wire            [p_pixel_x_gain_bit + 7 - 1     : 0]    w_pixel_x_gain_brl_2st [p_ch_num_bit_msb : 0];//add 7 bit to save low bits for rnd const calculation
    wire            [p_pixel_x_gain_bit + 15 - 1    : 0]    w_pixel_x_gain_brl_3st_rnd [p_ch_num_bit_msb : 0];//add 15 bit to save low bits for rnd const calculation

    wire    signed  [p_pixel_x_gain_bit - 1         : 0]    w_pixel_x_gain_scld [p_ch_num_bit_msb : 0];

    wire            [p_pixel_x_gain_bit - 1         : 0]    w_rnd_val [p_ch_num_bit_msb : 0];

    wire            [p_ch_num_bit_msb               : 0]    w_pixel_oflw;
    wire            [p_ch_num_bit_msb               : 0]    w_pixel_uflw;

    reg             [p_k_bit - 1                    : 0]    r_pixel_clp [p_ch_num_bit_msb : 0];
    wire            [p_k_bit - 1                    : 0]    w_pixel_out [p_ch_num_bit_msb : 0];
    reg             [p_k_bit - 1                    : 0]    r_pixel_out_pp2 [p_ch_num_bit_msb : 0];


    assign  w_reg_foo_pedestal     =   i_REG_FOO_PEDESTAL;


    assign w_gain[0]  =   i_COEFF_VEC [p_foo_gain_bit - 1        : 0];
    assign w_gain[1]  =   i_COEFF_VEC [2*p_foo_gain_bit - 1      : p_foo_gain_bit];
    assign w_gain[2]  =   i_COEFF_VEC [3*p_foo_gain_bit - 1      : 2*p_foo_gain_bit];

    always @( * )
        begin: mx_bay_pat
            case ( { i_Y_LSB, i_ARR_TYPE } )
                //RGGB
                3'b000 :
                    begin
                        r_gain_bayer [0]     =  w_gain[0];
                        r_gain_bayer [1]     =  w_gain[1];
                    end
                3'b100 :
                    begin
                        r_gain_bayer [0]     =  w_gain[1];
                        r_gain_bayer [1]     =  w_gain[2];
                    end
                //GRBG
                3'b001 :
                    begin
                        r_gain_bayer [0]     =  w_gain[1];
                        r_gain_bayer [1]     =  w_gain[0];
                    end
                3'b101 :
                    begin
                        r_gain_bayer [0]     =  w_gain[2];
                        r_gain_bayer [1]     =  w_gain[1];
                    end
                //GBRG
                3'b010 :
                    begin
                        r_gain_bayer [0]     =  w_gain[1];
                        r_gain_bayer [1]     =  w_gain[2];
                    end
                3'b110 :
                    begin
                        r_gain_bayer [0]     =  w_gain[0];
                        r_gain_bayer [1]     =  w_gain[1];
                    end
                //BGGR
                3'b011 :
                    begin
                        r_gain_bayer [0]     =  w_gain[2];
                        r_gain_bayer [1]     =  w_gain[1];
                    end
                default ://'b111
                    begin
                        r_gain_bayer [0]     =  w_gain[1];
                        r_gain_bayer [1]     =  w_gain[0];
                    end
            endcase
        end

    genvar ii;
    generate
        for (ii = 0; ii < p_ch_num_bit; ii=ii+1)
            begin: g_ch
                assign  w_pixel_in [ii]                 =   i_PIXELS [(ii+1)*p_k_bit-1 : ii*p_k_bit];

                assign  w_pixel_m_pedestal [ii]         =   $signed ( {1'b0, w_pixel_in [ii]} ) - $signed ( {2'd0, i_REG_FOO_PEDESTAL} );

                assign  w_pixel_x_gain [ii]             =   $signed ( {1'b0, r_gain_bayer [ii]} ) * w_pixel_m_pedestal [ii];

                assign  w_pixel_x_gain_brl_0st [ii]     =   ( 1'b1 == i_REG_FOO_Y_GAIN_SFT [0] )  ?
                                                            { {1{r_pixel_x_gain_pp1 [ii] [p_pixel_x_gain_bit - 1]}}, r_pixel_x_gain_pp1 [ii] } :
                                                            { r_pixel_x_gain_pp1 [ii], 1'd0 };

                assign  w_pixel_x_gain_brl_1st [ii]     =   ( 1'b1 == i_REG_FOO_Y_GAIN_SFT [1] )  ?
                                                            { {2{r_pixel_x_gain_pp1 [ii] [p_pixel_x_gain_bit - 1]}}, w_pixel_x_gain_brl_0st [ii] } :
                                                            { w_pixel_x_gain_brl_0st [ii], 2'd0 };

                assign  w_pixel_x_gain_brl_2st [ii]     =   ( 1'b1 == i_REG_FOO_Y_GAIN_SFT [2] )  ?
                                                            { {4{r_pixel_x_gain_pp1 [ii] [p_pixel_x_gain_bit - 1]}}, w_pixel_x_gain_brl_1st [ii] } :
                                                            { w_pixel_x_gain_brl_1st [ii], 4'd0 };

                assign  w_pixel_x_gain_brl_3st_rnd [ii] =   ( 1'b1 == i_REG_FOO_Y_GAIN_SFT [3] )  ?
                                                            { {8{r_pixel_x_gain_pp1 [ii] [p_pixel_x_gain_bit - 1]}}, w_pixel_x_gain_brl_2st [ii] } :
                                                            { w_pixel_x_gain_brl_2st [ii], 8'd0 };


                assign  w_rnd_val [ii] =  r_pixel_x_gain_pp1 [ii] [p_pixel_x_gain_bit - 1]  ?
                        w_pixel_x_gain_brl_3st_rnd [ii][14]  &
                        (
                            w_pixel_x_gain_brl_3st_rnd [ii][13] | w_pixel_x_gain_brl_3st_rnd [ii][12] |
                            w_pixel_x_gain_brl_3st_rnd [ii][11] | w_pixel_x_gain_brl_3st_rnd [ii][10] |
                            w_pixel_x_gain_brl_3st_rnd [ii][9]  | w_pixel_x_gain_brl_3st_rnd [ii][8]  |
                            w_pixel_x_gain_brl_3st_rnd [ii][7]  | w_pixel_x_gain_brl_3st_rnd [ii][6]  |
                            w_pixel_x_gain_brl_3st_rnd [ii][5]  | w_pixel_x_gain_brl_3st_rnd [ii][4]  |
                            w_pixel_x_gain_brl_3st_rnd [ii][3]  | w_pixel_x_gain_brl_3st_rnd [ii][2]  |
                            w_pixel_x_gain_brl_3st_rnd [ii][1]  | w_pixel_x_gain_brl_3st_rnd [ii][0]
                        )
                        :
                        w_pixel_x_gain_brl_3st_rnd [ii][14];


                assign  w_pixel_x_gain_scld [ii]   =   $signed (w_pixel_x_gain_brl_3st_rnd [ii] [p_pixel_x_gain_bit + 15 - 1 : 15]) + $signed (w_rnd_val [ii]);

                assign  w_pixel_p_pedestal [ii]   =   w_pixel_x_gain_scld [ii] +  $signed ( { {(p_pixel_x_gain_bit-p_pedestal_bit){1'b0}}, w_reg_foo_pedestal} );

                assign  w_pixel_oflw [ii] =   ( w_pixel_p_pedestal [ii] > $signed ({ {(p_pixel_x_gain_bit-14){1'b0}}, p_max_b14_bit }) ) ? 1'b1 : 1'b0;
                assign  w_pixel_uflw [ii] =   ( w_pixel_p_pedestal [ii] < $signed ({(p_pixel_x_gain_bit){1'b0}}) ) ? 1'b1 : 1'b0;


                always @( * )
                    begin: mx_clp
                        case ( { w_pixel_oflw [ii], w_pixel_uflw [ii] } )
                            2'b01       : r_pixel_clp [ii] =  p_min_b14_bit;
                            2'b10       : r_pixel_clp [ii] =  p_max_b14_bit;
                            default     : r_pixel_clp [ii] =  w_pixel_p_pedestal [ii] [p_k_bit - 1  : 0];//b14
                        endcase
                    end//always

                assign  w_pixel_out [ii] =   ( r_pixel_in_pp1 [ii] < i_REG_FOO_THRES_BAYER ) ? r_pixel_clp [ii] : r_pixel_in_pp1 [ii];

                assign  o_PIXELS[(ii+1)*p_k_bit-1 : ii*p_k_bit]   =   r_pixel_out_pp2 [ii];
            end
    endgenerate

    always @(posedge i_CLK or negedge i_RSTn)
        begin: ff_ppln
            if(!i_RSTn)
                begin
                    r_pixel_in_pp1 [0]                  <=  { (p_k_bit){1'b0} };
                    r_pixel_in_pp1 [1]                  <=  { (p_k_bit){1'b0} };
                    r_pixel_x_gain_pp1 [0]              <=  $signed ( { (p_pixel_x_gain_bit){1'b0} } );
                    r_pixel_x_gain_pp1 [1]              <=  $signed ( { (p_pixel_x_gain_bit){1'b0} } );

                    r_pixel_out_pp2 [0]                 <=  { (p_k_bit){1'b0} };
                    r_pixel_out_pp2 [1]                 <=  { (p_k_bit){1'b0} };
                end
            else
                begin
                    if ( i_ENA_VEC [0] )
                        begin
                            r_pixel_in_pp1 [0]          <=  w_pixel_in [0];
                            r_pixel_in_pp1 [1]          <=  w_pixel_in [1];
                            r_pixel_x_gain_pp1 [0]      <=  w_pixel_x_gain [0];
                            r_pixel_x_gain_pp1 [1]      <=  w_pixel_x_gain [1];
                            //r_reg_FOO_pedestal_pp1     <=  i_REG_FOO_PEDESTAL;//not for synthesis, only for debug
                        end

                    if ( i_ENA_VEC [1] )
                        begin
                            r_pixel_out_pp2 [0]         <=  w_pixel_out [0];
                            r_pixel_out_pp2 [1]         <=  w_pixel_out [1];
                        end
                end
        end

endmodule
