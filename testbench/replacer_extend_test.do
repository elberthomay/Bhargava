onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /replacer_extend_test/clk
add wave -noupdate /replacer_extend_test/clk_en
add wave -noupdate /replacer_extend_test/rst
add wave -noupdate /replacer_extend_test/vid_pnt
add wave -noupdate /replacer_extend_test/cnt_pnt
add wave -noupdate /replacer_extend_test/cnt_empty_pnt
add wave -noupdate /replacer_extend_test/vid_empty
add wave -noupdate /replacer_extend_test/cnt_empty
add wave -noupdate /replacer_extend_test/vid_in
add wave -noupdate -radix unsigned /replacer_extend_test/cnt_in
add wave -noupdate /replacer_extend_test/vid_rd
add wave -noupdate /replacer_extend_test/cnt_rd
add wave -noupdate /replacer_extend_test/data_out
add wave -noupdate /replacer_extend_test/data_wr
add wave -noupdate /replacer_extend_test/last_sign_in
add wave -noupdate /replacer_extend_test/out_afull
add wave -noupdate -divider internal
add wave -noupdate /replacer_extend_test/ex/module_en
add wave -noupdate /replacer_extend_test/ex/vid_ready
add wave -noupdate /replacer_extend_test/ex/cnt_ready
add wave -noupdate /replacer_extend_test/ex/cnt_reg_ready
add wave -noupdate /replacer_extend_test/ex/has_extend
add wave -noupdate -radix unsigned /replacer_extend_test/ex/cnt_reg
add wave -noupdate /replacer_extend_test/ex/next_decrement
add wave -noupdate /replacer_extend_test/ex/pointer
add wave -noupdate /replacer_extend_test/ex/cnt_reg_use
add wave -noupdate /replacer_extend_test/ex/next_data_wr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 257
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
WaveRestoreZoom {172 ns} {386 ns}
