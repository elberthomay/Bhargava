`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2022 02:48:31 PM
// Design Name: 
// Module Name: sync_debounce
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


module sync_debounce(
	input        clk,
	input        btn_in,
	output logic btn_out,
	output logic btn_posedge,
	output logic btn_negedge
);

	logic        btn_d0, btn_d1, btn_reg;
	logic [19:0] cnt;
	logic [2:0]  cnt_pipe;
	logic        next_btn_chng;
	
	always_ff @(posedge clk) {btn_d0, btn_d1, btn_reg} <= {btn_in, btn_d0, btn_d1};
	
	always_ff @(posedge clk)
		if(btn_reg ^ btn_out) cnt <= cnt + 1;
		else                  cnt <= 20'd0;
		
	always_ff @(posedge clk) begin
		cnt_pipe[2] <= &cnt[19:14];
		cnt_pipe[1] <= &cnt[13:8];
		cnt_pipe[0] <= &cnt[7:2];
	end
	
	always_comb next_btn_chng = &{cnt_pipe, cnt[1:0]};
	
	always_ff @(posedge clk)
		if(next_btn_chng) btn_out <= ~btn_out;
		else              btn_out <= btn_out;
		
	always_ff @(posedge clk) btn_posedge <= ~btn_out && next_btn_chng;
	always_ff @(posedge clk) btn_negedge <= btn_out && next_btn_chng;
		
endmodule
