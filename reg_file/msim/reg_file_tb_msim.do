.main clear
setenv MSIM 1
destroy	.wave

vlib work

vlog ../reg_file_tb.sv
vlog ../reg_file.v
vsim -t ns work.ttb

view -title reg_file wave
add wave -hex sim:/ttb/rst
add wave -hex sim:/ttb/clk
add wave -hex sim:/ttb/wr_en
add wave -hex sim:/ttb/rd_en
add wave -hex sim:/ttb/din
add wave -hex sim:/ttb/dout
add wave -hex sim:/ttb/uut/addr_shft_en
add wave -hex sim:/ttb/uut/addr0_shft_en
add wave -hex sim:/ttb/uut/data_shft_en_0
add wave -hex sim:/ttb/uut/data_shft_en_1
add wave -hex sim:/ttb/uut/wr_stage
add wave -hex sim:/ttb/uut/cnt
add wave -hex sim:/ttb/uut/addr_reg
add wave -hex sim:/ttb/uut/addr
add wave -hex sim:/ttb/uut/data_reg
add wave -hex sim:/ttb/value

run 200us




# backup

# vlog ../qua/simulation/modelsim/reg_file.vo
# vsim -t ns -sdftyp work.ttb.reg_file=../qua/simulation/modelsim/reg_file_v.sdo work.ttb

# vcom c:/intelFPGA_lite/20.1/quartus/eda/sim_lib/altera_mf_components.vhd
# vcom c:/intelFPGA_lite/20.1/quartus/eda/sim_lib/altera_mf.vhd
# vcom c:/intelFPGA_lite/20.1/quartus/eda/sim_lib/altera_primitives_components.vhd
# vcom c:/intelFPGA_lite/20.1/quartus/eda/sim_lib/altera_primitives.vhd
# vcom c:/intelFPGA_lite/20.1/quartus/eda/sim_lib/arriaii_atoms.vhd
# vcom c:/intelFPGA_lite/20.1/quartus/eda/sim_lib/arriaii_components.vhd
