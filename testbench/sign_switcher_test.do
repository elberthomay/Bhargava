onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sign_switcher_test/clk
add wave -noupdate /sign_switcher_test/clk_en
add wave -noupdate /sign_switcher_test/count_out_afull
add wave -noupdate /sign_switcher_test/mb_conf
add wave -noupdate /sign_switcher_test/first_group
add wave -noupdate /sign_switcher_test/has_one_group
add wave -noupdate /sign_switcher_test/sign_count
add wave -noupdate /sign_switcher_test/mb_conf_empty
add wave -noupdate /sign_switcher_test/sign_count_empty
add wave -noupdate /sign_switcher_test/sign_count_rd
add wave -noupdate /sign_switcher_test/mb_conf_rd
add wave -noupdate /sign_switcher_test/count_out
add wave -noupdate /sign_switcher_test/count_out_wr
add wave -noupdate -divider internal
add wave -noupdate /sign_switcher_test/sw/mb_conf_ready
add wave -noupdate /sign_switcher_test/sw/mb_conf_reg_ready
add wave -noupdate /sign_switcher_test/sw/sign_count_ready
add wave -noupdate /sign_switcher_test/sw/mb_conf_reg
add wave -noupdate /sign_switcher_test/sw/current_group
add wave -noupdate /sign_switcher_test/sw/group_empty
add wave -noupdate /sign_switcher_test/sw/current_conf
add wave -noupdate /sign_switcher_test/sw/last_group
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 234
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ns} {222 ns}
