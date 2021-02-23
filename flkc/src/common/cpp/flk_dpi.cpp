#ifdef __cplusplus
    extern	"C" {
#endif

typedef struct
    {
        int     reg_foo_y_gain_sft;
        int     reg_foo_thres_bayer;
        int     reg_foo_pedestal;
        int     arr_type;   //bayer pattern type
        int     y_lsb;      //even or odd row
        int     coeff_vec [3];  //coefficients for correction [3][10] bit
        int     pixels [2];
    } t_dut_in;


//C-class constructor
void *dut_gold_ref_new()
    {
        return new BP_FL_SRK;
    }


void foo_correction(
    void *inst,
    t_dut_in *p_in,
    int st_image [2],
    int *log)
    {
        //pointer to C-class containing all C-stuff.
        BP_FL_SRK *p_flk = (BP_FL_SRK *)inst;
        int bayer_pattern[4];

        // unpack_regs (t_dut_in, p_flk);
        p_flk->m_foo_param.FOO_Y_GAIN_SFT     = p_in->reg_foo_y_gain_sft;
        p_flk->m_foo_param.FOO_THRES_BAYER    = p_in->reg_foo_thres_bayer;
        p_flk->m_foo_param.FOO_PEDESTAL       = p_in->reg_foo_pedestal;

        p_flk->rgb2bayer (p_in->coeff_vec, p_in->arr_type, bayer_pattern);

        int even = p_in->y_lsb;//even or odd row

        for (int ch = 0; ch < 2; ch++)
        {
            st_image [ch] = p_in->pixels [ch];
            p_flk->XYShadingFooCorrect (st_image+ch, bayer_pattern [(2*even) + ch]);
        }
        return;
    } // foo

#ifdef __cplusplus
    }
#endif



