vlib work
vlog ./Fractional_Decimator/*.*v
vlog {./IIR notch filter/*.*v}

vlog ./*.*v

vsim -voptargs=+acc work.TOP_MODULE_TB
add wave *
run -all 