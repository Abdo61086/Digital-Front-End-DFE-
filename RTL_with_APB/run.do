vlib work

vlog -work work "./Fractional_Decimator/*.v"
vlog -work work "./IIR notch filter/*.v"
vlog -work work "./CIC_filter/*.v"
vlog -work work "./DFE_TOP/*.v"
vlog -work work "./TOP/*.v"

# Compile Top and TB
vlog -work work TOP_MODULE_TB.v



# Start Simulation
vsim -voptargs=+acc work.TOP_MODULE_TB

# --- POWER MONITORING SETUP ---
power add -r /TOP_MODULE_TB/DUT/*

add wave *
run -all

# --- EXPORT SAIF ---
power report -all -bsaif switching_activity.saif