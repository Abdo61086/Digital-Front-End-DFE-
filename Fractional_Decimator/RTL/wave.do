onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /Fractional_Decimator_tb/CLK_tb
add wave -noupdate /Fractional_Decimator_tb/RST_tb
add wave -noupdate /Fractional_Decimator_tb/x_n_tb
add wave -noupdate /Fractional_Decimator_tb/DUT/x_n_up
add wave -noupdate /Fractional_Decimator_tb/DUT/counter
add wave -noupdate /Fractional_Decimator_tb/DUT/accum
add wave -noupdate /Fractional_Decimator_tb/DUT/y_comb
add wave -noupdate -radix unsigned /Fractional_Decimator_tb/idx
add wave -noupdate -color yellow -itemcolor yellow /Fractional_Decimator_tb/y_m_tb
add wave -noupdate /Fractional_Decimator_tb/DUT/valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40260 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {40258 ns} {40281 ns}
