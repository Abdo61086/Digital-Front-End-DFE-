vlib work
vlog Fractional_Decimator.v Fractional_Decimator_tb.v
vsim -voptargs=+acc work.Fractional_Decimator_tb
do wave.do
run -all 