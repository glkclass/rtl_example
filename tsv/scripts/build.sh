#!/bin/bash
source /tools/Xilinx/Vivado/2023.2/settings64.sh

# cleanup
# rm -rf *

# compile dutb stuff
DUTB_PATH="/home/anton.voloshchuk/design/dutb"
xvlog -f $DUTB_PATH/util/util_file_opt.list

# compile current project stuff
xvlog -f ../scripts/file_opt.list


# elaborate design 
xelab -O0 -L fifo_generator_v13_2_9 tsv_top -s sim_snapshot -relax -timescale 1ns/1ps;  

# xelab -O0 tsv_top -s sim_snapshot -relax -timescale 1ns/1ps;  
# xsim sim_snapshot -R

   