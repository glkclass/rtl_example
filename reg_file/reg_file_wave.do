
destroy	.wave
vsim -t ns work.ttb
view -title reg_file wave
add wave sim:/ttb/*
add wave sim:/ttb/UUT/*
run 50 us

























