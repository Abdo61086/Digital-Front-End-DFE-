vlib work

# Use *.v (or *.sv for SystemVerilog)
vlog -work work "./Fractional_Decimator/*.v"
vlog -work work "./IIR notch filter/*.v"
vlog -work work "./CIC_filter/*.v"

# Compile Top and TB
vlog -work work clk_div.v TOP_MODULE.v TOP_MODULE_TB.v

# Start Simulation
vsim -voptargs=+acc work.TOP_MODULE_TB
add wave *
run -all
