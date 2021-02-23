#pragma once

#include <string>
#include "log.h"

#define MAX_B14 16383
#define MIN_B14 0

#define MAX_C15 16383
#define MIN_C15 -16383


typedef     short unsigned   uint16;
typedef     long unsigned   uint32;

enum    bayer_t {RGGB=0, GRBG, GBRG, BGGR};
enum    color_e{R=0, G, B, color_e_len};
enum    rc_e {ROW=0, COL, rc_e_len};
enum    yx_e {Y=0, X, yx_e_len};

enum    image_e { ST=0, LV, thread_num};
enum    rc_descr_e { REAL=0, REDUCED, rc_descr_e_len};
enum    t_modes {ori=0, hw, both };

typedef uint16  rc_t[thread_num][rc_e_len];
typedef uint16  cord_t[thread_num];//[rc_descr_e_len];

typedef uint16  mux_t[thread_num][color_e_len];
typedef bool    ena_t[thread_num][color_e_len];
typedef uint16  ch_t[thread_num][color_e_len][2];
typedef uint16  tile_t[thread_num][rc_e_len];

class BP_FL_SRK : public PP_FOO
{

public:

    typedef struct stFOO_PARAM
    {
        int FOO_THRES_BAYER;       //b14
        int FOO_Y_GAIN_SFT;        //b4,
        int FOO_PEDESTAL;          //b14,
    }tFOO_PARAM;

    tFOO_PARAM m_foo_param;

    tile_t  tile;
    cord_t  row;
    cord_t  col;
    rc_t    rc;
    bool    yx_ena [yx_e_len];

    int gapLV_H;
    int gapLV_V;

    int gapST_H;
    int gapST_V;

    t_modes mode;
    // 4 debug
    ch_t    ena_bit;
    void    *debug_ptr;
    void    *dbg_hw_ptr;

    BP_FL_SRK(void);
    virtual ~BP_FL_SRK(void);

    virtual void calc_avg   (int* raw, int avg[5][64], int array_type, int color);
            int gain_adder(int y, int* linegain);
            int gain_adder_div_check(int y, int* linegain, int *, int *);//temp version for divider bit width checking
            void rgb2bayer  (int* p_rgb_gain, int array_type, int *bayer_pattern);
            void XYShadingFooCorrect (int *pixel, int gain);
            int XYS_Fronter_CAL(int in, int y_gain);
            int rounding(int in, unsigned int sht);
            int clip_minmax(int val, int min, int max);
    };
