//`undef DES
`define DES 1

`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2022 08:07:08 PM
// Design Name: 
// Module Name: bhargava_test
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


module bhargava_test(

    );
	reg clk_en, rst_n_200, rst_n_300, rst_n;
	
	integer r, file, file_out, status;
	reg [7:0] mem[0:50000000];
	
	
	
	wire       mpeg_prog_full;
	
	reg clk, clk2x;
	
	integer down_time = 0;
	
	
	reg [7:0]  mpeg_in;
	reg        mpeg_wr, stream_end;
	
	wire [7:0] mpeg_out;
	wire       mpeg_rd;
	reg        mpeg_ready;
	wire       mpeg_empty;
	integer in_cnt = 0;
	integer out_cnt = 0;
	
	wire [31:0] vid_cnt, misc_in_cnt, vbuf_out_cnt, vlc_cnt_bit, ex_cnt_cnt, sign_cnt_cnt, 
			   sign_switch_cnt, replacer_sign_cnt, replacer_extend_cnt;
	wire [31:0] vlc_sign_cnt, collator_sign_cnt, mb_ser_sign_cnt, dese64_sign_cnt, 
		       post_des_sign_cnt, unscrambler_sign_cnt, post_unscr_ser_sign_cnt;
	wire [28:0] vlc_cnt_byte, ex_cnt_cnt_byte, sign_cnt_cnt_byte, sign_switch_cnt_byte;
	wire [2:0] vlc_cnt_rem, ex_cnt_cnt_rem, sign_cnt_cnt_rem, sign_switch_cnt_rem;
	
	wire       vlc_sign_bit;
	wire       mb_ser_sign_bit;
	wire       post_des_ser_sign_bit;
	wire       post_unscr_ser_sign_bit;
	
	
	
	initial mpeg_in = 8'h00;
	initial mpeg_wr = 1'b0;
	initial stream_end = 1'b0;

	//clk
	initial clk = 1'b1;
	always #15 clk = ~clk;
	
	//clk
	initial clk2x = 1'b1;
	always #10 clk2x = ~clk2x;
	
	//clk_en
	initial clk_en = 1'b1;
	
	`ifdef DES
	
	reg [63:0] key_in;
	reg        mode_in;
	reg        key_en;
	
	initial begin
		key_in = 64'ha1b2c3d4e5f61234;
		
		mode_in = 1'b0;
		
		key_en = 1'b0;
		#150 key_en = 1'b0;
		@(posedge clk2x) key_en = 1'b1;
		@(posedge clk2x) key_en = 1'b0;
	end
	`endif
	
	
	
	//rst_n
	//initial begin
	//	rst_n = 1'b0;
	//	#105 @(posedge clk);
	//	@(posedge clk) rst_n <= 1'b1;
	//end
	
	//rst_n_200
	initial begin
		 rst_n_200 = 1'b0;
		#105 @(posedge clk);
		@(posedge clk) rst_n_200 <= 1'b1;
	end
	
	//rst_n_300
	initial begin
		 rst_n_300 = 1'b0;
		#105 @(posedge clk2x);
		@(posedge clk2x) rst_n_300 <= 1'b1;
	end
	
	//file
	initial begin
		file = $fopen("dats/bjork.mpg", "rb");	//bjork_snippet5
		if (!file) begin
			$error("could not read file");
			$stop;
		end
		r = $fread(mem, file);
	end
	
	//mpeg_in and mpeg_wr
	
	
	always @(posedge clk) begin
		if(rst_n_200 && ~mpeg_prog_full && in_cnt < r)begin	//47519745 7724 1494 1640
			mpeg_in <= mem[in_cnt];
			mpeg_wr <= 1'b1;
			in_cnt = in_cnt + 1;
		end
		else if(in_cnt == r) begin
			stream_end <= 1'b1;
			mpeg_wr <= 1'b0;
		end
		else begin
			mpeg_wr <= 1'b0;
		end
	end
	
	always @(posedge clk)
		if(mpeg_prog_full) down_time = down_time + 1;
	
	//mpeg_rd
	assign mpeg_rd = ~mpeg_empty;
	
	//mpeg_ready
	always @(posedge clk) mpeg_ready <= mpeg_rd;
	
	//mpeg_out
`ifdef DES
	initial begin
		file_out = $fopen("dats/des_out.mpg", "wb");
		if (!file_out) begin
			$error("could not open file");
			$stop;
		end
	end
	
	always @(posedge clk) begin
		if(mpeg_ready) begin
			$fwrite(file_out, "%c", mpeg_out);
			out_cnt = out_cnt + 1;
			if(out_cnt == in_cnt && out_cnt != 0) $fclose(file_out);
		end
	end
`else
	always @(posedge clk) begin
		if(mpeg_ready)begin	
			if(mpeg_out != mem[out_cnt])begin
				$display("error at byte %d", out_cnt);
				$stop;
			end
			out_cnt = out_cnt + 1;
		end
	end
`endif
	
	bhargava bhargava_inst(
		.clk(clk),
	    .clk2x(clk2x),
		.clk_en(clk_en),
		.rst_n_200(rst_n_200),
		.rst_n_300(rst_n_300),
        .mpeg_in(mpeg_in),
		.stream_end(stream_end),
        .mpeg_wr(mpeg_wr),
		
	`ifdef DES
		.key_in(key_in),
		.mode_in(mode_in),
		.key_en(key_en),
	`endif
		
		.mpeg_out(mpeg_out),
        .mpeg_rd(mpeg_rd),
		.mpeg_empty(mpeg_empty),
		.mpeg_prog_full(mpeg_prog_full),
		
		.vid_cnt(vid_cnt), 
        .misc_in_cnt(misc_in_cnt), 
        .vbuf_out_cnt(vbuf_out_cnt), 
        .vlc_cnt_bit(vlc_cnt_bit), 
        .ex_cnt_cnt(ex_cnt_cnt), 
        .sign_cnt_cnt(sign_cnt_cnt), 
        .sign_switch_cnt(sign_switch_cnt), 
        .replacer_sign_cnt(replacer_sign_cnt), 
        .replacer_extend_cnt(replacer_extend_cnt),
		.vlc_sign_cnt(vlc_sign_cnt), 
        .collator_sign_cnt(collator_sign_cnt), 
        .mb_ser_sign_cnt(mb_ser_sign_cnt), 
        .dese64_sign_cnt(dese64_sign_cnt), 
        .post_des_sign_cnt(post_des_sign_cnt), 
        .unscrambler_sign_cnt(unscrambler_sign_cnt),
		.post_unscr_ser_sign_cnt(post_unscr_ser_sign_cnt), 
		
		.vlc_cnt_byte(vlc_cnt_byte), 
        .ex_cnt_cnt_byte(ex_cnt_cnt_byte), 
        .sign_cnt_cnt_byte(sign_cnt_cnt_byte), 
        .sign_switch_cnt_byte(sign_switch_cnt_byte),
		.vlc_cnt_rem(vlc_cnt_rem), 
        .ex_cnt_cnt_rem(ex_cnt_cnt_rem), 
        .sign_cnt_cnt_rem(sign_cnt_cnt_rem), 
        .sign_switch_cnt_rem(sign_switch_cnt_rem),
	
	    .vlc_sign_bit(vlc_sign_bit), 
	    .mb_ser_sign_bit(mb_ser_sign_bit), 
	    .post_des_ser_sign_bit(post_des_ser_sign_bit), 
	    .post_unscr_ser_sign_bit(post_unscr_ser_sign_bit)
	);
	
endmodule
