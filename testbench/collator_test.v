`timescale 1ns/1ns

module collator_test();
	
	reg      clk, clk_en, rst, sign_en, sign_bit, group_change, macroblock_end, slice_end;
	
	reg  [2:0]  original_group[0:63];
	
	wire [90:0]  mb_conf;
	wire [2:0]  plainnum_m;
	wire [6:0]  plainnum[5:0];
	wire [6:0]  non_plainnum[5:0];
	wire [63:0] scrambled_plaintext;
	wire [6:0]  scrambled_count;
	wire [2:0]  scrambled_group[0:63];
	wire [0:63][5:0]  original_position;
	wire mb_wr, mb_conf_wr;

	initial begin
		clk = 1'b0;
		rst = 1'b0;
		clk_en = 1'b1;
		sign_en = 1'b0;
		sign_bit = 1'b0;
		group_change = 1'b0;
		macroblock_end = 1'b0;
		slice_end = 1'b0;
		@(posedge clk) rst <= 1'b1;
	end

	always begin
		#5 clk = ~clk;
	end
	integer i;
	always @(posedge clk)
		 if(mb_conf_wr)begin
			for(i = 0; i < 64; i = i+1)
				original_group[original_position[i]] = scrambled_group[i];
		end
		else original_group <= original_group;

	always @(posedge clk)if(sign_en) sign_bit <= ~sign_bit;

	task change_group(); 
		begin
			@(posedge clk) group_change = 1'b1;
			@(posedge clk) group_change = 1'b0;
			@(posedge clk) ;
		end
	endtask

	task sign_in(); 
		begin
			@(posedge clk) sign_en = 1'b1;
		end
	endtask

	task enter_sign(input [7:0] n); 
		begin
			for(;n >0; n = n - 1) sign_in();
			@(posedge clk) sign_en = 1'b0;
			change_group();
		end
	endtask
	
	task end_macroblock(); 
		begin
			@(posedge clk) macroblock_end = 1'b1;
			@(posedge clk) macroblock_end = 1'b0;
			@(posedge clk) ;
		end
	endtask

	initial begin
		@(posedge clk) ;
		
		enter_sign(0);
		enter_sign(3);
		enter_sign(4);
		enter_sign(0);
		enter_sign(31);
		enter_sign(2);
		enter_sign(50);

		end_macroblock();
		
		enter_sign(4);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);

		end_macroblock();

		enter_sign(0);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);
		enter_sign(64);

		end_macroblock();

		enter_sign(0);
		enter_sign(11);
		enter_sign(11);
		enter_sign(11);
		enter_sign(11);
		enter_sign(11);
		enter_sign(11);

		end_macroblock();

		enter_sign(4);
		enter_sign(10);
		enter_sign(10);
		enter_sign(10);
		enter_sign(10);
		enter_sign(10);
		enter_sign(10);

		end_macroblock();

		enter_sign(4);
		enter_sign(64);
		enter_sign(64);
		enter_sign(0);
		enter_sign(0);
		enter_sign(64);
		enter_sign(64);
	end
	
	assign {plainnum_m, 
	        plainnum[5], non_plainnum[5], 
	        plainnum[4], non_plainnum[4], 
			plainnum[3], non_plainnum[3], 
			plainnum[2], non_plainnum[2], 
			plainnum[1], non_plainnum[1], 
			plainnum[0], non_plainnum[0] } = mb_conf[86:0];


	collator col_test(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst), 
		.sign_en(sign_en), 
		.group_change(group_change), 
		.sign_bit(sign_bit), 
		.macroblock_end(macroblock_end), 
		.slice_end(slice_end), 
		.mb_conf(mb_conf), 
		.mb_wr(mb_wr),
		.mb_conf_wr(mb_conf_wr),
		.scrambled_plaintext(scrambled_plaintext), 
		.scrambled_count(scrambled_count),
		.scrambled_group(scrambled_group), 
		.original_position(original_position));
	
endmodule