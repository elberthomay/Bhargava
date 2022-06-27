onerror { resume }
transcript off
add wave -noreg -logic {/DES_single_test/clk}
add wave -noreg -logic {/DES_single_test/clk_en}
add wave -noreg -logic {/DES_single_test/rst}
add wave -noreg -hexadecimal -literal {/DES_single_test/data_in}
add wave -noreg -logic {/DES_single_test/data_en}
add wave -noreg -logic {/DES_single_test/des_busy}
add wave -noreg -hexadecimal -literal {/DES_single_test/data_out}
add wave -noreg -logic {/DES_single_test/des_wr}
add wave -noreg -logic {/DES_single_test/key_en}
add wave -noreg -hexadecimal -literal {/DES_single_test/key_in}
add wave -noreg -logic {/DES_single_test/mode_in}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/initial_key}
add wave -noreg -logic {/DES_single_test/des/state}
add wave -noreg -logic {/DES_single_test/des/next}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/cnt}
add wave -noreg -logic {/DES_single_test/des/shift_n}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/key_cd}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/key}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/data_reg}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/next_cnt}
add wave -noreg -logic {/DES_single_test/des/end_enq}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/E.in}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/E.E}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/S.in}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/S.S}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/P.in}
add wave -noreg -hexadecimal -literal {/DES_single_test/des/P.P}
cursor "Cursor 1" 69ps  
transcript on
