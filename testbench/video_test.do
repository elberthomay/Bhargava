onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /video_test/clk
add wave -noupdate /video_test/clk_en
add wave -noupdate /video_test/rst
add wave -noupdate -divider input
add wave -noupdate /video_test/vid_in
add wave -noupdate /video_test/vid_in_empty
add wave -noupdate /video_test/vid_in_rd_en
add wave -noupdate /video_test/fifo/vid_in_rd_valid
add wave -noupdate /video_test/fifo/dta
add wave -noupdate /video_test/fifo/next_dta
add wave -noupdate /video_test/fifo/state
add wave -noupdate /video_test/fifo/next
add wave -noupdate -radix unsigned /video_test/fifo/cursor
add wave -noupdate -radix unsigned /video_test/fifo/next_cursor
add wave -noupdate -radix unsigned /video_test/fifo/next_shift
add wave -noupdate /video_test/fifo/next_getbits
add wave -noupdate /video_test/getbits
add wave -noupdate -divider vid
add wave -noupdate /video_test/vld_en
add wave -noupdate -radix unsigned /video_test/advance
add wave -noupdate /video_test/vld/state
add wave -noupdate /video_test/align
add wave -noupdate -radix unsigned /video_test/advance_reg
add wave -noupdate /video_test/align_reg
add wave -noupdate /video_test/sign_en
add wave -noupdate /video_test/sign_loc
add wave -noupdate /video_test/sign_bit
add wave -noupdate /video_test/has_escape
add wave -noupdate /video_test/vld/type_change
add wave -noupdate /video_test/macroblock_end
add wave -noupdate /video_test/slice_end
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 210
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
WaveRestoreZoom {2137 ns} {2367 ns}
