@echo off

echo Starting Regression Test... > regression.rpt

vlog -work work "./Fractional_Decimator/*.v" "./IIR notch filter/*.v" "./CIC_filter/*.v" "./DFE_TOP/*.v" "./TOP/*.v" TOP_MODULE_TB.v


::vsim -voptargs=+acc work.CIC_tb -do "add wave * ; run -all" 


echo "================ Test 1: Fractional Decimator =====================" >> regression.rpt

vsim -c -voptargs=+acc work.Fractional_Decimator_tb -do "run -all; quit" | grep Status >> regression.rpt 

echo "================     Test 2: Notch Filter     =====================" >> regression.rpt

vsim -c -voptargs=+acc work.Notch_Filter_tb -do "run -all; quit" | grep Status >> regression.rpt 

echo "================      Test 3: CIC Filter      =====================" >> regression.rpt
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=000 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=001 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=010 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=011 -do "run -all; quit" | grep Status >> regression.rpt 
vsim -c -voptargs=+acc work.CIC_tb +CIC_D=100 -do "run -all; quit" | grep Status >> regression.rpt 

echo "================         System Test          =====================" >> regression.rpt
vsim -c -voptargs=+acc work.TOP_MODULE_TB -do "run -all; quit" | grep Status >> regression.rpt 

