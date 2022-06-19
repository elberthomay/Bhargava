module replacer(
	input              clk, clk_en, rst,
	input        [7:0] vid_in, cnt_in, extend_cnt_in,
	input              vid_empty, cnt_empty, extend_cnt_empty,
	input              sign_in,
	input              sign_empty,
	input              fifo_full,
	input              proc_vid_full,
	
	output logic       vid_rd, cnt_rd, extend_cnt_rd, sign_rd,
	output logic [7:0] new_vid_out,
	output logic       new_vid_wr,
	
);
	logic [7:0] vid_reg;
	logic       vid_reg_ready;
	
	always_ff @(posedge clk)
		if(~rst) 
		
endmodule

module replacer_sign(
	input              clk, clk_en, rst, 
	input [7:0]        data_in, cnt_in, 
	input              data_empty, cnt_empty,
	input              sign_in,
	input              sign_empty,
	input              out_full,
	
	output logic       data_rd, cnt_rd, sign_rd, 
	output logic [7:0] data_out, 
	output logic       data_wr, 
	output logic       last_sign_out
);
	logic       data_ready;
	logic       cnt_ready;
	logic       sign_ready;
	
	logic [7:0] data_reg;
	logic       data_reg_ready;
	
	logic       has_sign;
	logic [6:0] cnt_reg;
	logic       cnt_reg_ready;
	
	logic [3:0] next_decrement;
	logic [2:0] pointer;
	
	logic       next_data_wr;
	logic       cnt_reg_use;
	
	//data_ready
	always_ff @(posedge clk)
		if(~rst)        data_ready <= 1'b0;
		else if(clk_en) data_ready <= (data_rd && ~data_empty) || (data_ready && data_reg_ready && ~next_data_wr);
		else            data_ready <= data_ready;
		
	//cnt_ready
	always_ff @(posedge clk)
		if(~rst)        cnt_ready <= 1'b0;
		else if(clk_en) cnt_ready <= (cnt_rd && ~cnt_empty) || (cnt_ready && (cnt_reg_ready && cnt_reg > next_decrement ) );
		else            cnt_ready <= cnt_ready;
		
	//sign_ready
	always_ff @(posedge clk)
		if(~rst)        sign_ready <= 1'b0;
		else if(clk_en) sign_ready <= (sign_rd && ~sign_empty) || (sign_ready && ~has_sign);
		else            sign_ready <= sign_ready;
		
	
	//data_reg
	always_ff @(posedge clk)
		//if(~rst) data_reg <= 8'h0;
		if(clk_en && (~data_reg_ready || next_data_wr) )                data_reg <= data_in;
		else if(clk_en && cnt_reg_ready && has_sign && sign_ready) data_reg[pointer] <= sign_in;
		else                                                            data_reg <= data_reg;
		
	//data_reg_ready
	always_ff @(posedge clk)
		if(~rst)        data_reg_ready <= 1'b0;
		else if(clk_en) data_reg_ready <= data_ready || (data_reg_ready && ~next_data_wr);
		else            data_reg_ready <= data_reg_ready;
		
	//has_sign
	always_ff @(posedge clk)
		if(~rst)                                                                    has_sign <= 1'b0;
		else if(clk_en && (~cnt_reg_ready || cnt_reg <= next_decrement) ) has_sign <= cnt_in[7];
		else if(clk_en && sign_ready)                                               has_sign <= 1'b0;
		else                                                                        has_sign <= has_sign;
		
	//cnt_reg
	always_ff @(posedge clk)
		if(~rst)                                                                    cnt_reg <= 1'b0;
		else if(clk_en && (~cnt_reg_ready || cnt_reg <= next_decrement) ) cnt_reg <= cnt_in[6:0];
		else if(clk_en && (~has_sign || sign_ready) )                               cnt_reg <= cnt_reg - next_decrement;
		else                                                                        cnt_reg <= cnt_reg;
		
	//cnt_reg_ready
	always_ff @(posedge clk)
		if(~rst)        cnt_reg_ready <= 1'b0;
		else if(clk_en) cnt_reg_ready <= cnt_ready || (cnt_reg_ready && ~cnt_reg_use );
		else            cnt_reg_ready <= cnt_reg_ready;
		
	//next_decrement
	always_ff @(posedge clk)
		if(~rst || (clk_en && next_data_wr) )                               next_decrement <= 4'd8;
		else if(clk_en && cnt_reg_ready && (~has_sign || sign_ready) ) next_decrement <= next_decrement - cnt_reg;
		else                                                                next_decrement <= next_decrement;
	
	//pointer
	always_ff @(posedge clk)
		if(~rst || (clk_en && next_data_wr) ) pointer <= 3'd7;
		else if(clk_en && cnt_reg_ready && (~has_sign || sign_ready) ) pointer <= pointer - cnt_reg;
		else                                                                pointer <= pointer;
		
	
		
	//assign data_rd = (~data_ready || ~data_reg_ready || next_data_wr) && clk_en;
	//assign cnt_rd = (~cnt_ready || ~cnt_reg_ready || cnt_reg_use) && clk_en;
	
	always_ff @(posedge clk)
		if(~rst)        data_rd <= 1'b0;
		else if(clk_en) data_rd <= ~data_ready || ~data_reg_ready || next_data_wr;
		else            data_rd <= data_rd;
		
	always_ff @(posedge clk)
		if(~rst)        cnt_rd <= 1'b0;
		else if(clk_en) cnt_rd <= ~cnt_ready || ~cnt_reg_ready || cnt_reg_use;
		else            cnt_rd <= cnt_rd;
		
	assign next_data_wr = data_reg_ready && cnt_reg_ready && cnt_reg >= next_decrement && (~has_sign || sign_ready);
	assign cnt_reg_use = cnt_reg <= next_decrement && (~has_sign || sign_ready );
		
	assign sign_rd = (~sign_ready || has_sign);
		
endmodule

module replacer_extend(
	input              clk, clk_en, rst,
	input        [7:0] data_in, extend_cnt_in, 
	input              data_empty, extend_cnt_empty,
	input              last_sign_in, 
	input              out_full,
	
	output logic       data_rd, extend_cnt_rd, 
	output logic [7:0] data_out,
	output logic       data_wr
);
	logic data_ready;
	logic data_reg;
	logic data_reg_ready;
	
endmodule