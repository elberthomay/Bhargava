`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/14/2022 08:48:25 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx
#(
	parameter CLK_FREQ = 50,
	parameter BAUD_RATE = 115200,
	parameter DATA_LEN = 8,
	parameter PARITY = "NONE",
	parameter STOP = "ONE"
)
(
	input         clk,
	input         rst_n,
	input [7:0]   data_in,
	input         tx_en, 
	output logic  tx_out,
	output logic  busy
);

	localparam           CYCLE = CLK_FREQ * 1000000 / BAUD_RATE;
	
	bit                  parity_en, parity_set, parity_bit;
	bit                  stop_one_half, stop_two;
	
	initial begin
		case(PARITY)
			"NONE"  : begin
					      parity_en = 1'b0;
						  parity_set = 1'b0;
						  parity_bit = 1'b0;
					  end
			"ODD"  : begin
					      parity_en = 1'b1;
						  parity_set = 1'b1;
						  parity_bit = 1'b1;
					 end
			"EVEN"  : begin
					      parity_en = 1'b1;
						  parity_set = 1'b1;
						  parity_bit = 1'b0;
					 end
			"SPACE" : begin
					      parity_en = 1'b1;
						  parity_set = 1'b0;
						  parity_bit = 1'b0;
					  end
			"MARK"  : begin
					      parity_en = 1'b1;
						  parity_set = 1'b0;
						  parity_bit = 1'b1;
					  end
			default   begin
					      parity_en = 1'b0;
						  parity_set = 1'b0;
						  parity_bit = 1'b0;
					  end
		
		endcase
	end
	
	initial begin
		case(STOP)
			"ONE"  : begin
					     stop_one_half = 1'b0;
						 stop_two = 1'b0;
					 end
			"ONEHALF" : begin
					     stop_one_half = 1'b1;
						 stop_two = 1'b0;
					  end
			"TWO"  : begin
					     stop_one_half = 1'b0;
						 stop_two = 1'b1;
					  end
			default   begin
					     stop_one_half = 1'b0;
						 stop_two = 1'b0;
					  end
		
		endcase
	end
	
	parameter [2:0]
		STATE_IDLE = 3'd0, 
		STATE_START = 3'd1, 
		STATE_SEND_BYTE = 3'd2, 
		STATE_PARITY = 3'd3,
		STATE_STOP = 3'd4, 
		STATE_STOP_ONEHALF = 3'd5, 
		STATE_STOP_TWO = 3'd6;

		
	logic [2:0]  state, next;
	
	logic [7:0]  data_reg;
	logic [15:0] cycle_cnt;
	logic [2:0]  bit_ptr;
	logic        data_par;
	logic        next_tx_out;
	
	wire         full_pulse, half_pulse;
	
	//next
	always_comb begin
		casez(state)
			STATE_IDLE         : next = tx_en ? STATE_START : STATE_IDLE;
			
			STATE_START        : next = full_pulse ? STATE_SEND_BYTE : STATE_START;
			
			STATE_SEND_BYTE    : if(full_pulse && bit_ptr == DATA_LEN-1 && parity_en) next = STATE_PARITY;
							     else if(full_pulse && bit_ptr == DATA_LEN-1)         next = STATE_STOP;
							     else                                                 next = STATE_SEND_BYTE;
							  
			STATE_PARITY       : next = full_pulse ? STATE_STOP : STATE_PARITY;
			
			STATE_STOP         : if(full_pulse && stop_one_half) next = STATE_STOP_ONEHALF;
							     else if(full_pulse && stop_two) next = STATE_STOP_TWO;
							     else if(full_pulse)             next = STATE_IDLE;
								 else                            next = STATE_STOP;
							 
			STATE_STOP_ONEHALF : next = half_pulse? STATE_IDLE : STATE_STOP_ONEHALF;
			
			STATE_STOP_TWO     : next = full_pulse? STATE_IDLE : STATE_STOP_TWO;
							 
			default              next = STATE_IDLE;
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
		if(~rst_n)                                      bit_ptr <= 3'd0;
		else if(state == STATE_IDLE)                    bit_ptr <= 3'b0;
		else if(state == STATE_SEND_BYTE && full_pulse) bit_ptr <= bit_ptr + 1;
		else                                            bit_ptr <= bit_ptr;
		
	//data_par
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                                      data_par <= 1'b0;
		else if(state == STATE_IDLE)                    data_par <= 1'b0;
		else if(state == STATE_SEND_BYTE && half_pulse) data_par <= data_par ^ data_reg[bit_ptr];
		else                                            data_par <= data_par;
		
	//data_reg
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n)                            data_reg <= 8'h0;
		else if(state == STATE_IDLE && tx_en) data_reg <= data_in;
		else                                  data_reg <= data_reg;
		
	
	//tx_out
	initial tx_out = 1'b1;
	
	always_comb begin
		casez(state)
			STATE_IDLE         : next_tx_out = 1'b1;
			
			STATE_START        : next_tx_out = 1'b0;
			
			STATE_SEND_BYTE    : next_tx_out = data_reg[bit_ptr];
							  
			STATE_PARITY       : next_tx_out = parity_set? data_par ^ parity_bit : parity_bit;
			
			STATE_STOP,
							 
			STATE_STOP_ONEHALF,
			
			STATE_STOP_TWO     : next_tx_out = 1'b1;
							 
			default              next_tx_out = 1'b1;
		endcase
	end
	
	always_ff @(posedge clk or negedge rst_n)
		if(~rst_n) tx_out <= 1'b1;
		else       tx_out <= next_tx_out;
		
	//always_ff @(posedge clk or negedge rst_n)
	//	if(~rst_n) busy <= 1'b0;
	//	else       busy <= state != STATE_IDLE;
	
	always_comb busy = state != STATE_IDLE;
	
	assign full_pulse = cycle_cnt == CYCLE - 1;
	assign half_pulse = cycle_cnt == CYCLE/2 - 1;
endmodule
