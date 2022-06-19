module collator(clk, clk_en, rst, sign_en, sign_bit, group_change, macroblock_end, slice_end, 
	mb_conf, first_group, has_one_group, scrambled_plaintext, original_position, scrambled_count, no_sign, mb_wr, mb_conf_wr,  scrambled_group);

	input      clk, clk_en, rst;
	input      sign_en, sign_bit;
	input      group_change;
	input      macroblock_end;
	input      slice_end;
	
	output     [90:0] mb_conf;
	output reg [2:0]  first_group;
	output reg        has_one_group;
	
	
	output            mb_wr;
	output            mb_conf_wr;
	
	
	reg        [2:0]  plainnum_m;				// number of motion plaintext signbit
	reg        [6:0]  plainnum[5:0];			// number of plaintext signbit
	reg        [6:0]  non_plainnum[5:0];		// number of signbit that are not included as plaintext
	
	output reg [0:63] scrambled_plaintext;	   // scrambled plaintext ready to encrypt
	output reg [0:63][5:0] original_position;
	output reg [6:0]  scrambled_count;
	output            no_sign;
	
	
	
	output reg        [2:0]  scrambled_group [0:63];
	reg               scrambled_empty;
	reg               scrambled_full;
	
	reg               even_bit, second_bit;
	reg               not_m_group;
	reg               first_bit_in_group;
	reg               first_3_bit_in_group;
	reg        [6:0]  next_comparator, comparator;
	reg        [2:0]  group;
	
	reg        [5:0]  next_original_position;
	reg        [5:0]  next_group_bigger_than_comparator;
	reg        [6:0]  next_group_plainnum_in_scrambled_preadd[2:0];
	reg        [6:0]  next_group_sign_position;
	reg        [0:63] next_group_equal_position_flag;
	reg        [0:63] next_group_more_than_position_flag;
	
	reg        [5:0]  bigger_than_comparator;
	reg        [6:0]  plainnum_in_scrambled_preadd[2:0];
	reg        [6:0]  next_sign_position;
	reg               position_out_of_bound;
	reg        [0:63] equal_position_flag;
	reg        [0:63] more_than_position_flag;
	//reg        [0:63] shift_flag;
	//reg        [0:63] inc_flag;
	
	wire       [6:0] plainnum_in_scrambled[5:0];
	
	genvar i;
	
	//scrambled_plaintext
	always @(posedge clk)
		if(~rst)                                             scrambled_plaintext[0] <= 1'b0;
		else if(clk_en && sign_en && equal_position_flag[0]) scrambled_plaintext[0] <= sign_bit;
		else                                                 scrambled_plaintext[0] <= scrambled_plaintext[0];
	
	//original_position
	generate for(i = 0; i < 64; i = i + 1)begin:ori_pos_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )                   original_position[i] <= 6'd0;
			else if(clk_en && sign_en && equal_position_flag[i] )     original_position[i] <= next_original_position;
			else if(clk_en && sign_en && more_than_position_flag[i] ) original_position[i] <= (scrambled_group[i-1] < scrambled_group[63]) && scrambled_full ? original_position[i-1] - 1 : original_position[i-1];
			else if(clk_en && sign_en && ~position_out_of_bound)      original_position[i] <= (scrambled_group[i] < scrambled_group[63]) && scrambled_full ? original_position[i] - 1 : original_position[i];
			else                                                      original_position[i] <= original_position[i];
	end
	endgenerate
		
	generate for(i = 1; i < 64; i = i + 1)begin:scrambled_gen
		always @(posedge clk)
			if(~rst)                                                 scrambled_plaintext[i] <= 1'b0;
			else if(clk_en && sign_en && equal_position_flag[i])     scrambled_plaintext[i] <= sign_bit;
			else if(clk_en && sign_en && more_than_position_flag[i]) scrambled_plaintext[i] <= scrambled_plaintext[i-1];
			else                                                     scrambled_plaintext[i] <= scrambled_plaintext[i];
	end
	endgenerate	
	
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end ) ) scrambled_count <= 7'd0;
		else if(clk_en && sign_en && scrambled_count != 64)        scrambled_count <= scrambled_count + 1;
		else                                                       scrambled_count <= scrambled_count;
	
	
	//even_bit
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) even_bit <= 1'b0;
		else if(clk_en && sign_en && not_m_group)                  even_bit <= ~even_bit;
		else                                                       even_bit <= even_bit;
	
	//second_bit
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) second_bit <= 1'b0;
		else if(clk_en && sign_en && not_m_group)                  second_bit <= ~first_bit_in_group;
		else                                                       second_bit <= second_bit;
		
	//not_m_group
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) not_m_group <= 1'b0;
		else if(clk_en && group_change)         not_m_group <= 1'b1;
		else                                    not_m_group <= not_m_group;
	
	//first_bit_in_group
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) first_bit_in_group <= 1'b1;
		else if(clk_en && sign_en)                                 first_bit_in_group <= 1'b0;
		else                                                       first_bit_in_group <= first_bit_in_group;
	
	//first_3_bit_in_group
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) first_3_bit_in_group <= 1'b1;
		else if(clk_en && sign_en && second_bit)                   first_3_bit_in_group <= 1'b0;
		else                                                       first_3_bit_in_group <= first_3_bit_in_group;
		
		
	//next_comparator
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) next_comparator <= 7'd5;
		else if(clk_en && sign_en && even_bit)                     next_comparator <= next_comparator + 7'd2;
		else                                                       next_comparator <= next_comparator;
		
	//comparator
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) comparator <= 7'd3;
		else if(clk_en && sign_en)                                 comparator <= next_comparator;
		else                                                       comparator <= comparator;
		
	//group
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) group <= 3'd6;
		else if(clk_en && group_change)         group <= group - 3'd1;
		else                                    group <= group;
	
	//plainnum_m
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )     plainnum_m <= 3'd0;
		else if(clk_en && sign_en && group == 3'd6) plainnum_m <= plainnum_m + 3'd1;
		else                                        plainnum_m <= plainnum_m;
	
	//plainnum
	generate for(i = 5; i >= 0; i = i - 1)begin:plainnum_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )                            plainnum[i] <= 7'd0;
			else if(clk_en && sign_en && ~position_out_of_bound && group == i) plainnum[i] <= plainnum[i] + 1;
			else if(clk_en && sign_en && ~position_out_of_bound &&             //
			        scrambled_full && scrambled_group[63] == i)                plainnum[i] <= plainnum[i] - 1;
			else                                                               plainnum[i] <= plainnum[i];
	end
	endgenerate
	
	//non_plainnum
	generate for(i = 5; i >= 0; i = i - 1)begin:non_plainnum_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )                                                non_plainnum[i] <= 7'd0;
			else if(clk_en && sign_en && ( (~position_out_of_bound && scrambled_group[63] == i) || //
			        (position_out_of_bound && group == i) ) )                                      non_plainnum[i] <= non_plainnum[i] + 1;
			else                                                                                   non_plainnum[i] <= non_plainnum[i];
	end
	endgenerate
	
	//scrambled_group
	always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )              scrambled_group[0] <= 3'd6;
			else if(clk_en && sign_en && equal_position_flag[0]) scrambled_group[0] <= group;
			else                                                 scrambled_group[0] <= scrambled_group[0];
			
	generate for(i = 1; i < 64; i = i + 1)begin:scrambled_group_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )                  scrambled_group[i] <= 3'd6;
			else if(clk_en && sign_en && equal_position_flag[i])     scrambled_group[i] <= group;
			else if(clk_en && sign_en && more_than_position_flag[i]) scrambled_group[i] <= scrambled_group[i-1];
			else                                                     scrambled_group[i] <= scrambled_group[i];
	end
	endgenerate
	
	//scrambled_empty
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) scrambled_empty <= 1'b1;
		else if(clk_en && sign_en)              scrambled_empty <= 1'b0;
		else                                    scrambled_empty <= scrambled_empty;
		
	//scrambled_full
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )              scrambled_full <= 1'b0;
		else if (clk_en && sign_en && scrambled_count == 63) scrambled_full <= 1'b1;
		else                                                 scrambled_full <= scrambled_full;
	
	//next_group_bigger_than_comparator
	generate for(i = 5; i >= 0; i = i - 1)begin:next_bigger_than_comparator_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) ) next_group_bigger_than_comparator[i] <= 1'b0;
			else if(clk_en && sign_en)              next_group_bigger_than_comparator[i] <= plainnum[i] >= 7'd3;
			else                                    next_group_bigger_than_comparator[i] <= next_group_bigger_than_comparator[i];
	end
	endgenerate
	
	//next_group_plainnum_in_scrambled_preadd
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )            next_group_plainnum_in_scrambled_preadd[2] <= 7'd0;
		else if(clk_en && sign_en && (group == 3'd5 ||     //
		        group == 3'd4) && first_3_bit_in_group)    next_group_plainnum_in_scrambled_preadd[2] <= next_group_plainnum_in_scrambled_preadd[2] + 1;
		else                                               next_group_plainnum_in_scrambled_preadd[2] <= next_group_plainnum_in_scrambled_preadd[2];
	
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )            next_group_plainnum_in_scrambled_preadd[1] <= 7'd0;
		else if(clk_en && sign_en && (group == 3'd3 ||     //
		        group == 3'd2) && first_3_bit_in_group)    next_group_plainnum_in_scrambled_preadd[1] <= next_group_plainnum_in_scrambled_preadd[1] + 1;
		else                                               next_group_plainnum_in_scrambled_preadd[1] <= next_group_plainnum_in_scrambled_preadd[1];
	
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )            next_group_plainnum_in_scrambled_preadd[0] <= 7'd1;
		else if(clk_en && sign_en && (group == 3'd1 ||     //
		        group == 3'd0) && first_3_bit_in_group)    next_group_plainnum_in_scrambled_preadd[0] <= next_group_plainnum_in_scrambled_preadd[0] + 1;
		else                                               next_group_plainnum_in_scrambled_preadd[0] <= next_group_plainnum_in_scrambled_preadd[0];
	
	//next_group_sign_position
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end))                              next_group_sign_position <= 7'd1;
		else if(clk_en && sign_en && (~not_m_group || first_bit_in_group) ) next_group_sign_position <= next_group_sign_position + 1;
		else                                                                next_group_sign_position <= next_group_sign_position;
		
	//next_group_equal_position_flag
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) next_group_equal_position_flag[0] <= 1'b1;
		else if(clk_en && sign_en)              next_group_equal_position_flag[0] <= 1'b0;
		else                                    next_group_equal_position_flag[0] <= next_group_equal_position_flag[0];
		
	generate for(i = 1; i < 64; i = i+1)begin:next_equal_position_flag_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )                             next_group_equal_position_flag[i] <= 1'b0;
			else if(clk_en && sign_en && (~not_m_group || first_bit_in_group) ) next_group_equal_position_flag[i] <= next_group_equal_position_flag[i-1];
			else                                                                next_group_equal_position_flag[i] <= next_group_equal_position_flag[i];
	end
	endgenerate
	
	//next_group_more_than_position_flag
	always @(posedge clk) next_group_more_than_position_flag[0] <= 1'b0;
		
	generate for(i = 1; i < 64; i = i+1)begin:next_more_than_position_flag_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end) )                             next_group_more_than_position_flag[i] <= 1'b1;
			else if(clk_en && sign_en && (~not_m_group || first_bit_in_group) ) next_group_more_than_position_flag[i] <= next_group_more_than_position_flag[i-1];
			else                                                                next_group_more_than_position_flag[i] <= next_group_more_than_position_flag[i];
	end
	endgenerate
	
	//bigger_than_comparator
	generate for(i = 5; i >= 0; i = i - 1)begin:bigger_than_comparator_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end)) bigger_than_comparator[i] <= 1'b0;
			else if(clk_en && group_change)        bigger_than_comparator[i] <= next_group_bigger_than_comparator[i];
			else if(clk_en && sign_en)             bigger_than_comparator[i] <= plainnum[i] > next_comparator;
			else                                   bigger_than_comparator[i] <= bigger_than_comparator[i];
	end
	endgenerate
	
	//plainnum_in_scrambled
	generate for(i = 5; i >= 0; i = i - 1)begin:plainnnum_in_gen
		assign plainnum_in_scrambled[i] = bigger_than_comparator[i] ? comparator: plainnum[i];
	end
	endgenerate
	
	//plainnum_in_scrambled_preadd
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) plainnum_in_scrambled_preadd[2] <= 7'd0;
		else if(clk_en && group_change)         plainnum_in_scrambled_preadd[2] <= next_group_plainnum_in_scrambled_preadd[2];
		else if(clk_en && sign_en)              plainnum_in_scrambled_preadd[2] <= plainnum_in_scrambled[5] + plainnum_in_scrambled[4] + not_m_group;
		else                                    plainnum_in_scrambled_preadd[2] <= plainnum_in_scrambled_preadd[2];
		
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) plainnum_in_scrambled_preadd[1] <= 7'd0;
		else if(clk_en && group_change)         plainnum_in_scrambled_preadd[1] <= next_group_plainnum_in_scrambled_preadd[1];
		else if(clk_en && sign_en)              plainnum_in_scrambled_preadd[1] <= plainnum_in_scrambled[3] + plainnum_in_scrambled[2];
		else                                    plainnum_in_scrambled_preadd[1] <= plainnum_in_scrambled_preadd[1];
	
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) plainnum_in_scrambled_preadd[0] <= 7'd1;
		else if(clk_en && group_change)         plainnum_in_scrambled_preadd[0] <= next_group_plainnum_in_scrambled_preadd[0];
		else if(clk_en && sign_en)              plainnum_in_scrambled_preadd[0] <= plainnum_in_scrambled[1] + plainnum_in_scrambled[0] + 1;
		else                                    plainnum_in_scrambled_preadd[0] <= plainnum_in_scrambled_preadd[0];
	
	//next_sign_position;
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) ) next_sign_position <= 7'd1;
		else if(clk_en && group_change)         next_sign_position <= next_group_sign_position;
		else if(clk_en && sign_en)              next_sign_position <= plainnum_m + plainnum_in_scrambled_preadd[2] + plainnum_in_scrambled_preadd[1] + plainnum_in_scrambled_preadd[0] + 7'd1;
		else                                    next_sign_position <= next_sign_position;
		
	//position_out_of_bound
	always @(posedge clk)
		if(~rst || (clk_en && (macroblock_end || group_change) ) ) position_out_of_bound <= 1'b0;
		else if(clk_en && sign_en)                                 position_out_of_bound <= next_sign_position[6];
		else                                                       position_out_of_bound <= position_out_of_bound;
		
	//equal_position_flag
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end)) equal_position_flag[0] <= 1'b1;
		else if(clk_en && group_change)        equal_position_flag[0] <= next_group_equal_position_flag[0];
		else if(clk_en && sign_en)             equal_position_flag[0] <= next_sign_position == 0;
		else                                   equal_position_flag[0] <= equal_position_flag[0];
			
	generate for(i = 1; i < 64; i = i + 1)begin:equal_position_flag_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end)) equal_position_flag[i] <= 1'b0;
			else if(clk_en && group_change)        equal_position_flag[i] <= next_group_equal_position_flag[i];
			else if(clk_en && sign_en)             equal_position_flag[i] <= next_sign_position == i;
			else                                   equal_position_flag[i] <= equal_position_flag[i];
	end
	endgenerate
	
	//more_than_position_flag
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end)) more_than_position_flag[0] <= 1'b0;
		else if(clk_en && group_change)        more_than_position_flag[0] <= next_group_more_than_position_flag[0];
		else if(clk_en && sign_en)             more_than_position_flag[0] <= next_sign_position == 0;
		else                                   more_than_position_flag[0] <= more_than_position_flag[0];
			
	generate for(i = 1; i < 64; i = i + 1)begin:more_than_position_flag_gen
		always @(posedge clk)
			if(~rst || (clk_en && macroblock_end)) more_than_position_flag[i] <= 1'b1;
			else if(clk_en && group_change)        more_than_position_flag[i] <= next_group_more_than_position_flag[i];
			else if(clk_en && sign_en)             more_than_position_flag[i] <= i > next_sign_position;
			else                                   more_than_position_flag[i] <= more_than_position_flag[i];
	end
	endgenerate
		
	//next_original_position
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )                    next_original_position <= 6'd0;
		else if(clk_en && sign_en && next_original_position != 63) next_original_position <= next_original_position + 1;
		else                                                       next_original_position <= next_original_position;
		
	//first_group
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )            first_group <= 3'd0;
		else if(clk_en && scrambled_empty && group_change) first_group <= first_group + 1;
		else                                               first_group <= first_group;
		
	//has_one_group
	always @(posedge clk)
		if(~rst || (clk_en && macroblock_end) )                has_one_group <= 1'b1;
		else if(clk_en && first_group != 6 - group && sign_en) has_one_group <= 1'b0;
		else                                                   has_one_group <= has_one_group;
	
	assign mb_conf = {4'h0, plainnum_m, 
	                  plainnum[5], non_plainnum[5], 
	                  plainnum[4], non_plainnum[4], 
					  plainnum[3], non_plainnum[3], 
					  plainnum[2], non_plainnum[2], 
					  plainnum[1], non_plainnum[1], 
					  plainnum[0], non_plainnum[0] };
					  
	assign mb_wr = clk_en && (~scrambled_empty || slice_end) && macroblock_end;
	assign mb_conf_wr = clk_en && ~scrambled_empty && macroblock_end;
	assign no_sign = slice_end && scrambled_empty;
	
endmodule
	
	