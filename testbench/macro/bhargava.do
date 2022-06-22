onerror { resume }
transcript off
add wave -noreg -logic {/bhargava_test/clk}
add wave -noreg -logic {/bhargava_test/clk2x}
add wave -noreg -logic {/bhargava_test/srst}
add wave -noreg -logic {/bhargava_test/mpeg_prog_full}
add wave -noreg -logic {/bhargava_test/stream_end}
add wave -noreg -hexadecimal -literal {/bhargava_test/mpeg_in}
add wave -noreg -logic {/bhargava_test/mpeg_in_en}
add wave -noreg -hexadecimal -literal {/bhargava_test/mpeg_out}
add wave -noreg -logic {/bhargava_test/mpeg_out_en}
add wave -noreg -hexadecimal -literal -signed2 {/bhargava_test/down_time}
add wave -noreg -vgroup "vid fifo to replacer"  {/bhargava_test/bhargava_inst/vid_fifo_inst/empty} {/bhargava_test/bhargava_inst/replacer_sign_inst/vid_rd} {/bhargava_test/bhargava_inst/vid_fifo_inst/dout} {/bhargava_test/bhargava_inst/replacer_sign_inst/vid_ready} {/bhargava_test/bhargava_inst/replacer_sign_inst/vid_reg_ready} {/bhargava_test/bhargava_inst/replacer_sign_inst/data_out} {/bhargava_test/bhargava_inst/replacer_sign_inst/data_wr}
add wave -noreg -vgroup "replacer_extend"  {/bhargava_test/bhargava_inst/replacer_extend_inst/cnt_reg_ready} {/bhargava_test/bhargava_inst/replacer_extend_inst/cnt_reg} {/bhargava_test/bhargava_inst/replacer_extend_inst/next_decrement} {/bhargava_test/bhargava_inst/replacer_extend_inst/vid_in} {/bhargava_test/bhargava_inst/replacer_extend_inst/vid_ready} {/bhargava_test/bhargava_inst/replacer_extend_inst/data_out} {/bhargava_test/bhargava_inst/replacer_extend_inst/data_wr}
add wave -noreg -vgroup "getbits to vld"  {/bhargava_test/bhargava_inst/getbits_inst/vld_en} {/bhargava_test/bhargava_inst/video_inst/align_reg} {/bhargava_test/bhargava_inst/video_inst/advance_reg} {/bhargava_test/bhargava_inst/video_inst/sign_loc} {/bhargava_test/bhargava_inst/video_inst/sign_en} {/bhargava_test/bhargava_inst/video_inst/macroblock_end} {/bhargava_test/bhargava_inst/video_inst/slice_end}
add wave -noreg -vgroup "sign_counter"  {/bhargava_test/bhargava_inst/sign_counter_inst/advance} {/bhargava_test/bhargava_inst/sign_counter_inst/align} {/bhargava_test/bhargava_inst/sign_counter_inst/sign_en} {/bhargava_test/bhargava_inst/sign_counter_inst/sign_loc} {/bhargava_test/bhargava_inst/sign_counter_inst/sign_en_reg} {/bhargava_test/bhargava_inst/sign_counter_inst/counter} {/bhargava_test/bhargava_inst/sign_counter_inst/cnt_wr} {/bhargava_test/bhargava_inst/sign_counter_inst/cnt_out}
add wave -noreg -vgroup "sign_counter to sign_replacer.reg"  {/bhargava_test/bhargava_inst/sign_counter_inst/cnt_out} {/bhargava_test/bhargava_inst/sign_counter_inst/cnt_wr} {/bhargava_test/bhargava_inst/sign_switcher_inst/count_out} {/bhargava_test/bhargava_inst/sign_switcher_inst/count_out_wr} {/bhargava_test/bhargava_inst/replacer_sign_inst/cnt_empty} {/bhargava_test/bhargava_inst/replacer_sign_inst/cnt_ready} {/bhargava_test/bhargava_inst/replacer_sign_inst/cnt_in} {/bhargava_test/bhargava_inst/replacer_sign_inst/cnt_reg_ready} {/bhargava_test/bhargava_inst/replacer_sign_inst/cnt_reg} {/bhargava_test/bhargava_inst/replacer_sign_inst/next_decrement} {/bhargava_test/bhargava_inst/replacer_sign_inst/sign_ready}
add wave -noreg -vgroup "collator mb_ser"  {/bhargava_test/bhargava_inst/collator_inst/scrambled_plaintext} {/bhargava_test/bhargava_inst/collator_inst/original_position} {/bhargava_test/bhargava_inst/collator_inst/scrambled_count} {/bhargava_test/bhargava_inst/collator_inst/slice_end} {/bhargava_test/bhargava_inst/collator_inst/no_sign} {/bhargava_test/bhargava_inst/collator_inst/macroblock_end} {/bhargava_test/bhargava_inst/mb_ser_inst/sign_in} {/bhargava_test/bhargava_inst/mb_ser_inst/pos_in} {/bhargava_test/bhargava_inst/mb_ser_inst/size_in} {/bhargava_test/bhargava_inst/mb_ser_inst/slice_end} {/bhargava_test/bhargava_inst/mb_ser_inst/no_sign} {/bhargava_test/bhargava_inst/mb_ser_inst/mb_ready} {/bhargava_test/bhargava_inst/mb_ser_inst/mb_reg_ready} {/bhargava_test/bhargava_inst/mb_ser_inst/last_in_mb} {/bhargava_test/bhargava_inst/mb_ser_inst/slice_end_out} {/bhargava_test/bhargava_inst/mb_ser_inst/sign_out} {/bhargava_test/bhargava_inst/mb_ser_inst/pos_out} {/bhargava_test/bhargava_inst/mb_ser_inst/out_wr}
add wave -noreg -vgroup "sign line"  {/bhargava_test/bhargava_inst/dese64_inst/sign_in} {/bhargava_test/bhargava_inst/dese64_inst/sign_wr} {/bhargava_test/bhargava_inst/dese64_inst/slice_end} {/bhargava_test/bhargava_inst/dese64_inst/wr_ptr} {/bhargava_test/bhargava_inst/dese64_inst/sign_reg} {/bhargava_test/bhargava_inst/dese64_inst/size_reg} {/bhargava_test/bhargava_inst/dese64_inst/size_out} {/bhargava_test/bhargava_inst/dese64_inst/sign_out} {/bhargava_test/bhargava_inst/dese64_inst/des_wr} {/bhargava_test/bhargava_inst/dese64_inst/last_wr} {/bhargava_test/bhargava_inst/pos_des_ser_inst/des_in} {/bhargava_test/bhargava_inst/pos_des_ser_inst/last_in} {/bhargava_test/bhargava_inst/pos_des_ser_inst/last_size} {/bhargava_test/bhargava_inst/pos_des_ser_inst/des_wr} {/bhargava_test/bhargava_inst/pos_des_ser_inst/last_filled} {/bhargava_test/bhargava_inst/pos_des_ser_inst/last_ack} {/bhargava_test/bhargava_inst/pos_des_ser_inst/sign_out} {/bhargava_test/bhargava_inst/pos_des_ser_inst/sign_en}
add wave -noreg -vgroup "unscrambler"  {/bhargava_test/bhargava_inst/unscrambler_inst/sign_en} {/bhargava_test/bhargava_inst/unscrambler_inst/pos_in} {/bhargava_test/bhargava_inst/unscrambler_inst/pos_ready} {/bhargava_test/bhargava_inst/unscrambler_inst/size_reg} {/bhargava_test/bhargava_inst/unscrambler_inst/mb_end} {/bhargava_test/bhargava_inst/unscrambler_inst/unscrambler_out} {/bhargava_test/bhargava_inst/unscrambler_inst/unscrambler_size}
add wave -noreg -vgroup "post unscr"  {/bhargava_test/bhargava_inst/post_unscr_ser_inst/data_in} {/bhargava_test/bhargava_inst/post_unscr_ser_inst/size_in} {/bhargava_test/bhargava_inst/post_unscr_ser_inst/unscrambled_ready} {/bhargava_test/bhargava_inst/post_unscr_ser_inst/data_reg} {/bhargava_test/bhargava_inst/post_unscr_ser_inst/size_reg} {/bhargava_test/bhargava_inst/post_unscr_ser_inst/bit_out} {/bhargava_test/bhargava_inst/post_unscr_ser_inst/bit_wr}
add wave -named_row "count"
add wave -noreg -hexadecimal -literal -signed2 {/bhargava_test/in_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/misc_in_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/vid_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/vbuf_out_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/vlc_cnt_byte}
add wave -noreg -hexadecimal -literal {/bhargava_test/vlc_cnt_rem}
add wave -named_row "side line"
add wave -noreg -hexadecimal -literal {/bhargava_test/ex_cnt_cnt_byte}
add wave -noreg -hexadecimal -literal {/bhargava_test/ex_cnt_cnt_rem}
add wave -noreg -hexadecimal -literal {/bhargava_test/sign_cnt_cnt_byte}
add wave -noreg -hexadecimal -literal {/bhargava_test/sign_cnt_cnt_rem}
add wave -noreg -hexadecimal -literal {/bhargava_test/sign_switch_cnt_byte}
add wave -noreg -hexadecimal -literal {/bhargava_test/sign_switch_cnt_rem}
add wave -noreg -hexadecimal -literal {/bhargava_test/replacer_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/replacer_extend_cnt}
add wave -noreg -hexadecimal -literal -signed2 {/bhargava_test/out_cnt}
add wave -named_row "sign line"
add wave -noreg -hexadecimal -literal {/bhargava_test/vlc_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/collator_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/mb_ser_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/dese64_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/post_des_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/unscrambler_sign_cnt}
add wave -noreg -hexadecimal -literal {/bhargava_test/post_unscr_ser_sign_cnt}
add wave -named_row "sign bits"
add wave -noreg -logic {/bhargava_test/vlc_sign_bit}
add wave -noreg -logic {/bhargava_test/post_unscr_ser_sign_bit}
add wave -noreg -logic {/bhargava_test/post_des_ser_sign_bit}
add wave -noreg -logic {/bhargava_test/mb_ser_sign_bit}
cursor "Cursor 1" 1967.37us  
transcript on
