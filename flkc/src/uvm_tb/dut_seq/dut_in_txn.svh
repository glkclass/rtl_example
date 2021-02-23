// input dut transaction - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
class dut_in_txn extends dut_txn_base;
    `uvm_object_utils(dut_in_txn)

    class regs;
        rand logic    [p_y_gain_sft_bit - 1  : 0]           foo_y_gain_sft;
        rand logic    [p_thres_bayer_bit - 1 : 0]           foo_thres_bayer;
        rand logic    [p_pedestal_bit - 1 : 0]              foo_pedestal;

        constraint c_foo_y_gain_sft { foo_y_gain_sft <= p_y_gain_sft_max; }
        constraint c_foo_thres_bayer { foo_thres_bayer <= p_thres_bayer_max; }
        constraint c_foo_pedestal { foo_pedestal <= p_pedestal_max; }
    endclass
    regs reg_h;

    class inputs;
        rand logic      [p_ch_num - 1 : 0]                  arr_type;   //bayer pattern type
        rand logic                                          y_lsb;      //even or odd row
        rand logic      [p_foo_gain_bit - 1 : 0]            coeff_vec [p_rgb_num];  //coefficients for correction [3][10] bit
        rand logic      [p_k_bit - 1 : 0]                   pixel [p_ch_num];

        constraint c_arr_type { arr_type < 4; }
        constraint c_y_lsb    { y_lsb < 2; }
        constraint c_coeff_vec
            {
                coeff_vec[0] < 1024;
                coeff_vec[1] < 1024;
                coeff_vec[2] < 1024;
            }
        constraint c_pixel
            {
                pixel[0] < 4096;
                pixel[1] < 4096;
            }
    endclass
    inputs input_h;


    extern function new(string name = "dut_in_txn");
    extern virtual function void do_copy (uvm_object rhs);  // make a deep copy
    extern virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
    extern virtual function string convert2string ();  // represent 'txn content' as string
    extern virtual function vector pack2vector ();  // represent 'txn content' as 'vector of int'
    extern virtual function void unpack4vector (vector packed_txn); //extract 'txn content' from 'vector of int'
    extern function void write (virtual dut_if dut_vif);  // write 'txn content' to interface
    extern function void read (virtual dut_if dut_vif);  // read 'txn content' from interface
endclass


function dut_in_txn::new(string name = "dut_in_txn");
    super.new(name);
    reg_h = new();
    input_h = new();
endfunction


function void dut_in_txn::do_copy(uvm_object rhs);
    dut_in_txn _rhs;
    if(!$cast(_rhs, rhs))
        begin
            `uvm_error("TXN_DO_COPY", "Txn cast was failed")
            return;
        end
    super.do_copy(rhs); // chain the copy with parent classes

    reg_h.foo_y_gain_sft           = _rhs.reg_h.foo_y_gain_sft;
    reg_h.foo_thres_bayer        = _rhs.reg_h.foo_thres_bayer;
    reg_h.foo_pedestal           = _rhs.reg_h.foo_pedestal;

    input_h.arr_type        = _rhs.input_h.arr_type;
    input_h.y_lsb           = _rhs.input_h.y_lsb;
    input_h.coeff_vec       = _rhs.input_h.coeff_vec;
    input_h.pixel           = _rhs.input_h.pixel;
endfunction


function bit dut_in_txn::do_compare(uvm_object rhs, uvm_comparer comparer);
    dut_in_txn _rhs;
    // If the cast fails, comparison has also failed
    // A check for null is not needed because that is done in the compare() function which calls do_compare()
    if(!$cast(_rhs, rhs))
        begin
            return 0;
        end

    return (
                super.do_compare(rhs, comparer) &&
                (reg_h.foo_y_gain_sft        == _rhs.reg_h.foo_y_gain_sft) &&
                (reg_h.foo_thres_bayer       == _rhs.reg_h.foo_thres_bayer) &&
                (reg_h.foo_pedestal          == _rhs.reg_h.foo_pedestal) &&

                (input_h.arr_type             == _rhs.input_h.arr_type) &&
                (input_h.y_lsb                == _rhs.input_h.y_lsb) &&
                (input_h.coeff_vec            == _rhs.input_h.coeff_vec) &&
                (input_h.pixel                == _rhs.input_h.pixel)
            );
endfunction


function string dut_in_txn::convert2string();
    return $sformatf
        (
            "regs[0..2]: %0d %0d %0d\ni_input_h.arr_type: %0d\ni_input_h.y_lsb: %0d\ninput_h.coeff_vec[0..2]: %0d %0d %0d\ni_input_h.pixel[0..1]: %0d %0d",
            reg_h.foo_y_gain_sft,
            reg_h.foo_thres_bayer,
            reg_h.foo_pedestal,

            input_h.arr_type,
            input_h.y_lsb,
            input_h.coeff_vec[0], input_h.coeff_vec[1], input_h.coeff_vec[2],
            input_h.pixel[0], input_h.pixel[1]
        );
endfunction


function vector dut_in_txn::pack2vector();
    return
        {
            reg_h.foo_y_gain_sft,
            reg_h.foo_thres_bayer,
            reg_h.foo_pedestal,

            input_h.arr_type,
            input_h.y_lsb,
            input_h.coeff_vec, // int[3]
            input_h.pixel // int[2]
        };
endfunction


function void dut_in_txn::unpack4vector(vector packed_txn);
    reg_h.foo_y_gain_sft   = packed_txn[0];
    reg_h.foo_thres_bayer  = packed_txn[1];
    reg_h.foo_pedestal     = packed_txn[2];
    input_h.arr_type        = packed_txn[3];
    input_h.y_lsb           = packed_txn[4];
    input_h.coeff_vec       = { packed_txn[5], packed_txn[6], packed_txn[7] };
    input_h.pixel           = { packed_txn[8], packed_txn[9] };
endfunction


function void dut_in_txn::write(virtual dut_if dut_vif);
    if (reg_valid)
        begin
            dut_vif.i_REG_FOO_Y_GAIN_SFT                                   = reg_h.foo_y_gain_sft;
            dut_vif.i_REG_FOO_THRES_BAYER                                  = reg_h.foo_thres_bayer;
            dut_vif.i_REG_FOO_PEDESTAL                                     = reg_h.foo_pedestal;
        end

    if (input_valid)
        begin
            dut_vif.i_ARR_TYPE                                              = input_h.arr_type;
            dut_vif.i_Y_LSB                                                 = input_h.y_lsb;
            dut_vif.i_COEFF_VEC[p_foo_gain_bit - 1 : 0]                    = input_h.coeff_vec[0];
            dut_vif.i_COEFF_VEC[2*p_foo_gain_bit - 1 : p_foo_gain_bit]    = input_h.coeff_vec[1];
            dut_vif.i_COEFF_VEC[3*p_foo_gain_bit - 1 : 2*p_foo_gain_bit]  = input_h.coeff_vec[2];
            dut_vif.i_PIXELS[p_k_bit - 1 : 0]                               = input_h.pixel[0];
            dut_vif.i_PIXELS[2*p_k_bit - 1 : p_k_bit]                       = input_h.pixel[1];
        end
endfunction


function void dut_in_txn::read(virtual dut_if dut_vif);
    content_valid = dut_vif.i_ENA_VEC[0];
    if (1'b1 == content_valid)
        begin
            reg_h.foo_y_gain_sft           = dut_vif.i_REG_FOO_Y_GAIN_SFT;
            reg_h.foo_thres_bayer          = dut_vif.i_REG_FOO_THRES_BAYER;
            reg_h.foo_pedestal             = dut_vif.i_REG_FOO_PEDESTAL;

            input_h.arr_type                = dut_vif.i_ARR_TYPE;
            input_h.y_lsb                   = dut_vif.i_Y_LSB;
            input_h.coeff_vec[0]            = dut_vif.i_COEFF_VEC[p_foo_gain_bit - 1 : 0];
            input_h.coeff_vec[1]            = dut_vif.i_COEFF_VEC[2*p_foo_gain_bit - 1 : p_foo_gain_bit];
            input_h.coeff_vec[2]            = dut_vif.i_COEFF_VEC[3*p_foo_gain_bit - 1 : 2*p_foo_gain_bit];
            input_h.pixel[0]                = dut_vif.i_PIXELS[p_k_bit - 1 : 0];
            input_h.pixel[1]                = dut_vif.i_PIXELS[2*p_k_bit - 1 : p_k_bit];
        end
endfunction
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
