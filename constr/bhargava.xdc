






















set_property PACKAGE_PIN AB11 [get_ports clk_200_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_200_p]

set_property PACKAGE_PIN C24 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PACKAGE_PIN L25 [get_ports rx_in]
set_property PACKAGE_PIN M25 [get_ports tx_out]
set_property IOSTANDARD LVCMOS33 [get_ports rx_in]
set_property IOSTANDARD LVCMOS33 [get_ports tx_out]


set_property MARK_DEBUG false [get_nets {mpeg_out[0]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[1]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[2]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[3]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[4]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[5]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[6]}]
set_property MARK_DEBUG false [get_nets {mpeg_out[7]}]
set_property MARK_DEBUG false [get_nets mpeg_ready]
set_property PACKAGE_PIN Y12 [get_ports mpeg_full_led]
set_property IOSTANDARD LVCMOS15 [get_ports mpeg_full_led]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]





