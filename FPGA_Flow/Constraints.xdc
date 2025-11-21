# ==============================================================================
# 1. CLOCK CONSTRAINTS
# ==============================================================================

# Master Clock (18 MHz) on input port PCLK
create_clock -period 55.556 -name PCLK -waveform {0.000 27.778} [get_ports {PCLK}]

# Generated Clock (Divide by 3 -> 6 MHz)
# Source: The MSB of the counter register inside the CLK_DIV module.
# Hierarchy: top_module -> u_dft_top -> CLK_DIV -> counter_reg
create_generated_clock -name clk_div_6M \
    -source [get_ports {PCLK}] \
    -divide_by 3 \
    [get_pins {u_dft_top/CLK_DIV/counter_reg[1]/Q}]


# ==============================================================================
# 2. INPUT DELAYS (External -> FPGA)
#    Generic Safe Values: Min 0ns, Max 10ns
# ==============================================================================

# Group 1: APB Control Signals (Single bits)
set_input_delay -clock [get_clocks PCLK] -min -add_delay 0.000 [get_ports {PRESETn PSEL PENABLE PWRITE}]
set_input_delay -clock [get_clocks PCLK] -max -add_delay 10.000 [get_ports {PRESETn PSEL PENABLE PWRITE}]

# Group 2: APB Address and Data Buses
set_input_delay -clock [get_clocks PCLK] -min -add_delay 0.000 [get_ports {PADDR[*] PWDATA[*]}]
set_input_delay -clock [get_clocks PCLK] -max -add_delay 10.000 [get_ports {PADDR[*] PWDATA[*]}]

# Group 3: DFE Input Data Bus
set_input_delay -clock [get_clocks PCLK] -min -add_delay 0.000 [get_ports {input_data[*]}]
set_input_delay -clock [get_clocks PCLK] -max -add_delay 10.000 [get_ports {input_data[*]}]


# ==============================================================================
# 3. OUTPUT DELAYS (FPGA -> External)
#    Generic Safe Values: Min 0ns, Max 10ns
# ==============================================================================

# Group 1: APB Read Data Output
set_output_delay -clock [get_clocks PCLK] -min -add_delay 0.000 [get_ports {PRDATA[*]}]
set_output_delay -clock [get_clocks PCLK] -max -add_delay 10.000 [get_ports {PRDATA[*]}]

# Group 2: DFE Output Data Bus
set_output_delay -clock [get_clocks PCLK] -min -add_delay 0.000 [get_ports {output_data[*]}]
set_output_delay -clock [get_clocks PCLK] -max -add_delay 10.000 [get_ports {output_data[*]}]
