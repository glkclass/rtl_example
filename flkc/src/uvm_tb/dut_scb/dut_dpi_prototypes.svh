// cpp-class constructor. Creates cpp-class containing all cpp-references(gold references).
import  "DPI-C" function chandle dut_gold_ref_new();

// c-protorypr proxy
import  "DPI-C" function void foo_correction
(
    input chandle inst,
    input int in[10],
    output int out[2],
    output int log [1]
);
