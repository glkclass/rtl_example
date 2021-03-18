.main clear

vlog reg_file.v
vlog reg_file_tb.sv

destroy	.wave
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

run 100 us