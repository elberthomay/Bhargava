//`timescale 1ns / 1ps
//`undef DES
`define DES 1
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2022 03:04:11 PM
// Design Name: 
// Module Name: bhargava_uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bhargava_uart(
	input clk_200_p, clk_200_n, rst_n, 
	output mpeg_full_led,
	input rx_in,
	output tx_out
);
	parameter 
		CLK_FREQ = 200,
		BAUD_RATE = 256000,
		DATA_LEN = 8,
		PARITY = "ODD",
		STOP = "ONE";
	
`ifdef DES
	parameter 
		STATE_KEY = 2'd0, 
		STATE_MODE = 2'd1, 
		STATE_DATA = 2'd2;
`else
	parameter STATE_DATA = 2'd0;
`endif	  
	
	wire clk_200;
	wire clk_300;
	
	wire rst_n_200;
	wire rst_n_300;
	
	wire [7:0]data_in;
	wire uart_data_valid;
	wire uart_parity_err;
	
	wire [7:0]mpeg_out;
	wire uart_tx_busy;
	wire mpeg_empty;
	wire mpeg_full;
	
	
	logic [1:0] state, next;
	logic [2:0] key_cnt;
	logic [63:0] key_reg;
	logic mode_reg;
	logic key_en_reg_0, key_en_reg_1;
	logic key_en_reg;
	
	logic mpeg_full_reg;
	
	logic stream_end_reg;
	
	logic mpeg_wr;
	
	logic mpeg_ready;
	logic mpeg_rd;
	logic tx_en;
	
`ifdef DES
	always_comb begin
		casez(state)
			STATE_KEY  : next = (uart_data_valid && key_cnt == 3'd7) ? STATE_MODE : STATE_KEY;
			STATE_MODE : next = (uart_data_valid) ? STATE_DATA : STATE_MODE;
			STATE_DATA : next = STATE_DATA;
		endcase
	end
	
	always_ff @(posedge clk_200)
		if(~rst_n_200)                                 key_cnt <= 3'd0;
		else if(state == STATE_KEY && uart_data_valid) key_cnt <= key_cnt + 1;
		else                                           key_cnt <= key_cnt;
		
	always_ff @(posedge clk_200)
		if(~rst_n_200)                                 key_reg <= 64'h0;
		else if(state == STATE_KEY && uart_data_valid) key_reg[63-(key_cnt*8) -: 8] <= data_in;
		else                                           key_reg <= key_reg;
		
	always_ff @(posedge clk_200)
		if(~rst_n_200)                                  mode_reg <= 1'b0;
		else if(state == STATE_MODE && uart_data_valid) mode_reg <= data_in[0];
		else                                            mode_reg <= mode_reg;
		
	always_ff @(posedge clk_200)
		if(~rst_n_200) key_en_reg <= 1'b0;
		else           key_en_reg <= state == STATE_MODE && uart_data_valid;
		
	always_ff @(posedge clk_300)
		{key_en_reg_0, key_en_reg_1} <= {key_en_reg, key_en_reg_0};
	
`else
	always_comb next = STATE_DATA;
`endif
	
	always_ff @(posedge clk_200)
		if(~rst_n_200) state <= 2'd0;
		else           state <= next;
		
	always_comb mpeg_wr = state == STATE_DATA && uart_data_valid;
	
	always_ff @(posedge clk_200)
		if(~rst_n_200)           stream_end_reg <= 1'b0;
		else if(uart_parity_err) stream_end_reg <= 1'b1;
		else                     stream_end_reg <= stream_end_reg;
		
	always_ff @(posedge clk_200)
		if(~rst_n_200) mpeg_ready <= 1'b0;
		else           mpeg_ready <= (mpeg_ready && uart_tx_busy) || mpeg_rd;
		
	always_ff @(posedge clk_200)
		if(~rst_n_200)     mpeg_full_reg <= 1'b0;
		else if(mpeg_full) mpeg_full_reg <= 1'b1;
		else               mpeg_full_reg <= mpeg_full_reg;
	
	always_comb mpeg_rd = ~mpeg_ready && ~mpeg_empty;
	
	always_comb tx_en = mpeg_ready && ~uart_tx_busy;
	
	assign mpeg_full_led = ~mpeg_full_reg;

	clk_wiz_400 clk_wiz_400_inst(
		.clk_in1_p(clk_200_p),
		.clk_in1_n(clk_200_n),
		.clk_200(clk_200),
		.clk_300(clk_300)
		//.reset(PCIE_PERST_B_LS)
	);
	
	sync_debounce rst_200_sync_inst(
		.clk(clk_200),
		.btn_in(rst_n),
		.btn_out(rst_n_200)
	);

	sync_debounce rst_300_sync_inst(
		.clk(clk_300),
		.btn_in(rst_n),
		.btn_out(rst_n_300)
	);
	
	uart_rx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_LEN(DATA_LEN),
		.PARITY(PARITY)
	)uart_rx_inst(
		.clk(clk_200),
		.rst_n(rst_n_200),
		.rx_in(rx_in),
		.rx_rd_ready(1'b1),
		.data_out(data_in),
		.data_valid(uart_data_valid), 
		.parity_err(uart_parity_err)
	);

	uart_tx #(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE),
		.DATA_LEN(DATA_LEN),
		.PARITY(PARITY),
		.STOP(STOP)
	)uart_tx_inst(
		.clk(clk_200),
		.rst_n(rst_n_200),
		.data_in(mpeg_out),
		.tx_en(tx_en), 
		.tx_out(tx_out),
		.busy(uart_tx_busy)
	);
	
	bhargava(
		.clk_200(clk_200),
		.clk_300(clk_300),
		.clk_en(1'b1),
	
		.rst_n_200(rst_n_200),
		.rst_n_300(rst_n_300),
		
		`ifdef DES
		.key_in(key_reg), 
		.mode_in(mode_reg),  
		.key_en(key_en_reg_1), 
		`endif
	
		.mpeg_in(data_in),
		.mpeg_wr(mpeg_wr),
		.mpeg_full(mpeg_full), 
		.stream_end(stream_end_reg),
	
		.mpeg_out(mpeg_out),
		.mpeg_rd(mpeg_rd),
	
		.mpeg_empty(mpeg_empty)
	);
endmodule
