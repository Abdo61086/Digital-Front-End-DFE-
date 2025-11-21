@echo off

vlog -work work "./Fractional_Decimator/*.v" "./IIR notch filter/*.v" "./CIC_filter/*.v" "./DFE_TOP/*.v" "./TOP/*.v" TOP_MODULE_TB.v


echo ==================================================================== > regression.rpt
echo                    REGRESSION TEST SUMMARY                           >> regression.rpt
echo ==================================================================== >> regression.rpt
echo. >> regression.rpt

echo TEST 1: FRACTIONAL DECIMATOR >> regression.rpt
echo -------------------------------------------------------------------- >> regression.rpt

vsim -c -voptargs=+acc work.Fractional_Decimator_tb -do "run -all; quit" | grep Status >> regression.rpt 

echo. >> regression.rpt
echo TEST 2: NOTCH FILTER >> regression.rpt
echo -------------------------------------------------------------------- >> regression.rpt

vsim -c -voptargs=+acc work.Notch_Filter_tb -do "run -all; quit" | grep Status >> regression.rpt 

echo. >> regression.rpt
echo TEST 3: CIC FILTER (Parameter Sweep) >> regression.rpt
echo -------------------------------------------------------------------- >> regression.rpt

vsim -c -voptargs=+acc work.CIC_tb +CIC_D=000 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=001 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=010 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=011 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=100 -do "run -all; quit" | grep Status >> regression.rpt 

echo. >> regression.rpt
echo TEST 4: SYSTEM LEVEL INTEGRATION >> regression.rpt
echo -------------------------------------------------------------------- >> regression.rpt

vsim -c -voptargs=+acc work.TOP_MODULE_TB -do "run -all; quit" | grep Status >> regression.rpt 

