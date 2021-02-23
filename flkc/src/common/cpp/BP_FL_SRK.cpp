// #include "global.h"
// #include "util.h"

extern int **pp_RGB_gain;
extern int **pp_foo_gain;
extern int *pp_foo_lv;
extern short *pp_foo_data;
extern int _im_(int i, int size);

BP_FL_SRK::BP_FL_SRK(void) : PP_FLICKER()
{
}

BP_FL_SRK::~BP_FL_SRK(void)
{
}

void BP_FL_SRK::XYShadingFooCorrect(int *pixel, int gain)
    {
        if (*pixel < m_foo_param.FOO_THRES_BAYER)
            {

                *pixel -= m_foo_param.FOO_PEDESTAL;
                *pixel = XYS_Fronter_CAL(*pixel, gain);
                *pixel += m_foo_param.FOO_PEDESTAL;
                *pixel = clip_minmax(*pixel, MIN_B14, MAX_B14);
            }
    }

int BP_FL_SRK::XYS_Fronter_CAL(int in, int y_gain)
{
    int out = rounding(in * y_gain, m_foo_param.FOO_Y_GAIN_SFT);
    return out;
}

int BP_FL_SRK::rounding(int in, unsigned int sht)
{
    if (sht == 0)
        return in;
    else {
        if (in < 0)
            return -((-in + (1 << (sht -1))) >> sht);
        else // in >= 0
            return (in + (1 << (sht -1))) >> sht;
    }
}

int BP_FL_SRK::clip_minmax(int val, int min_val, int max_val)
{
    if (val < min_val)
        return min_val;
    else if (val > max_val)
        return max_val;
    else
        return val;
}
