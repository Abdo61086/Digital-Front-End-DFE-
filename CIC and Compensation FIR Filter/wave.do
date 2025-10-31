onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ThirdStageTop_tb/clk_tb
add wave -noupdate /ThirdStageTop_tb/reset_tb
add wave -noupdate /ThirdStageTop_tb/y_valid_tb
add wave -noupdate /ThirdStageTop_tb/y_out_tb
add wave -noupdate /ThirdStageTop_tb/x_valid_tb
add wave -noupdate /ThirdStageTop_tb/x_in_tb
add wave -noupdate /ThirdStageTop_tb/status_ready_tb
add wave -noupdate /ThirdStageTop_tb/status_overflow_tb
add wave -noupdate /ThirdStageTop_tb/status_D_active_tb
add wave -noupdate /ThirdStageTop_tb/out_count
add wave -noupdate /ThirdStageTop_tb/i
add wave -noupdate /ThirdStageTop_tb/fout
add wave -noupdate /ThirdStageTop_tb/ctrl_reset_tb
add wave -noupdate /ThirdStageTop_tb/ctrl_enable_tb
add wave -noupdate /ThirdStageTop_tb/ctrl_decim_sel_tb
add wave -noupdate /ThirdStageTop_tb/ctrl_comp_enable_tb
add wave -noupdate /ThirdStageTop_tb/ce_out_tb
add wave -noupdate /ThirdStageTop_tb/clk_enable_tb
add wave -noupdate /ThirdStageTop_tb/CLOCK_PERIOD
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {638167943 ps} 0}
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
configure wave -timelineunits sec
update
WaveRestoreZoom {0 ps} {1086227172 ps}
