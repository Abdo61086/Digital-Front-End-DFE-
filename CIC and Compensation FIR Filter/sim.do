vlib work
vlog -sv -reportprogress 300 CIC.sv CompensationFIR.sv ThirdStageTop.sv ThirdStageTop_tb.sv
vsim -voptargs=+acc work.ThirdStageTop_tb
do wave.do
run -all
