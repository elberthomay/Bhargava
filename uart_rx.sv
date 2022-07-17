`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2022 09:39:49 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx
#(
	parameter CLK_FREQ = 50,
	parameter BAUD_RATE = 115200,
	parameter DATA_LEN = 8,
	parameter PARITY = "NONE"
)
(
	input                clk,
	input                rst_n,
	input                rx_in,
	input                rx_rd_ready,
	output logic [7:0]   data_out,
	output logic         data_valid, 
	output logic         parity_err
);

	localparam           CYCLE = CLK_FREQ * 1000000 / BAUD_RATE;
	
	bit                  parity_en, parity_check, parity_bit;
	
	initial begin
		case(PARITY)
			"NONE"  : begin
					      parity_en = 1'b0;
						  parity_check = 1'b0;
						  parity_bit = 1'b0;
					  end
			"ODD"  : begin
					      parity_en = 1'b1;
						  parity_check = 1'b1;
						  parity_bit = 1'b1;
					 end
			"EVEN"  : begin
					      parity_en = 1'b1;
						  parity_check = 1'b1;
						  parity_bit = 1'b0;
					 end
			"SPACE" : begin
					      parity_en = 1'b1;
						  parity_check = 1'b0;
						  parity_bit = 1'b0;
					  end
			"MARK"  : begin
					      parity_en = 1'b1;
						  parity_check = 1'b0;
						  parity_bit = 1'b1;
					  end
			default   begin
					      parity_en = 1'b0;
						  parity_check = 1'b0;
						  parity_bit = 1'b0;
					  end
		
		endcase
	end
	
	parameter [2:0]
		STATE_IDLE = 3'd0, 
		STATE_START = 3'd1, 
		STATE_REC_BYTE = 3'd2, 
		STATE_PARITY = 3'd3,
		STATE_STOP = 3'd4, 
		STATE_DATA = 3'd5;
		
	logic [2:0]  state, next;
	logic        rx_sync, rx_d0, rx_d1; //rx_in register
	
	logic [7:0]  data_reg;
	logic [15:0] cycle_cnt;
	logic [2:0]  bit_ptr;
	logic        par_bit;
	logic        par;
	
	wire         rx_negedge, full_pulse, half_pulse;
	
	//next
	always_comb begin
		casez(state)
			STATE_IDLE     : next = rx_negedge ? STATE_START : STATE_IDLE;
			STATE_START    : next = full_pulse ? STATE_REC_BYTE : STATE_START;
			STATE_REC_BYTE : if(full_pulse && bit_ptr == DATA_LEN-1 && parity_en)
			                     next = STATE_PARITY;
							 else if(full_pulse && bit_ptr == DATA_LEN-1)
							     next = STATE_STOP;
							 else next = STATE_REC_BYTE;
			STATE_PARITY   : next = full_pulse ? STATE_STOP : STATE_PARITY;
			STATE_STOP     : next = half_pulse ? STATE_DATA : STATE_STOP;
			STATE_DATA     : next = rx_rd_ready ? STATE_IDLE : STATE_DATA;
			default          next = STATE_IDLE;
		endcase
	end
	
	//state
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n) state <= STATE_IDLE;
		else       state <= next;
	
	//cycle_cnt
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                 cycle_cnt <= 16'd0;
		else if(state == STATE_IDLE || full_pulse) cycle_cnt <= 16'd0;
		else                                       cycle_cnt <= cycle_cnt + 1;
	
	//bit_ptr
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                     bit_ptr <= 3'd0;
		else if(state == STATE_IDLE)                   bit_ptr <= 3'b0;
		else if(state == STATE_REC_BYTE && full_pulse) bit_ptr <= bit_ptr + 1;
		else                                           bit_ptr <= bit_ptr;
		
	//par_bit
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                   par_bit <= 1'b0;
		else if(state == STATE_PARITY && half_pulse) par_bit <= rx_d1;
		else                                         par_bit <= par_bit;
		
	//par
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                                                 par <= 1'b0;
		else if(state == STATE_IDLE)                                               par <= 1'b0;
		else if( (state == STATE_REC_BYTE || state == STATE_PARITY) && half_pulse) par <= par ^ rx_d1;
		else                                                                       par <= par;
		
	//data_reg
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                     data_reg <= 8'h0;
		else if(state == STATE_REC_BYTE && half_pulse) data_reg[bit_ptr] <= rx_d1;
		else                                           data_reg <= data_reg;
		
	//data_out
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                  data_out <= 8'h0;
		else if(state == STATE_DATA && rx_rd_ready) data_out <= data_reg;
		else                                        data_out <= data_out;
		
	//data_valid
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n) data_valid <= 1'b0;
		else       data_valid <= (state == STATE_DATA && rx_rd_ready && (~parity_check || par == parity_bit) );
		
	//parity_err
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n) parity_err <= 1'b0;
		else       parity_err <= state == STATE_DATA && rx_rd_ready && ((parity_check && par != parity_bit) || (parity_en && ~parity_check && par_bit == parity_bit) ) ;
		
	//sync_regs
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n) {rx_sync, rx_d0, rx_d1} <= 3'b111;
		else       {rx_sync, rx_d0, rx_d1} <= {rx_in, rx_sync, rx_d0};
	
	assign rx_negedge = ~rx_d0 && rx_d1;
	assign full_pulse = cycle_cnt == CYCLE - 1;
	assign half_pulse = cycle_cnt == CYCLE/2 - 1;
endmodule
