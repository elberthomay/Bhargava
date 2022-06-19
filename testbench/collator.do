onerror { resume }
transcript off
add wave -noreg -logic {/collator_test/clk}
add wave -noreg -logic {/collator_test/clk_en}
add wave -noreg -hexadecimal -literal {/collator_test/enter_sign.n}
add wave -noreg -hexadecimal -literal {/collator_test/mb_conf}
add wave -noreg -logic {/collator_test/rst}
add wave -noreg -hexadecimal -literal {/collator_test/scrambled_count}
add wave -noreg -hexadecimal -literal {/collator_test/scrambled_plaintext}
add wave -noreg -logic {/collator_test/sign_bit}
add wave -noreg -logic {/collator_test/macroblock_end}
add wave -noreg -logic {/collator_test/slice_end}
add wave -noreg -logic {/collator_test/group_change}
add wave -noreg -logic {/collator_test/sign_en}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/next_group_bigger_than_comparator}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/next_group_plainnum_in_scrambled_preadd}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/next_group_sign_position}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/next_group_equal_position_flag}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/next_group_more_than_position_flag}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/bigger_than_comparator}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/plainnum_in_scrambled_preadd}
add wave -noreg -decimal -literal {/collator_test/col_test/next_sign_position}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/equal_position_flag}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/more_than_position_flag}
add wave -noreg -hexadecimal -literal {/collator_test/plainnum_m}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/plainnum}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/non_plainnum}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/scrambled_group}
add wave -noreg -hexadecimal -literal {/collator_test/col_test/original_position}
cursor "Cursor 1" 135ns  
transcript on
