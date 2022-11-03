module counter(
	input              clk, clk_en, rst,
	input        [4:0] advance,
	input              align,
	input              sign_en,
	input			   extend_en,
	input              sign_loc,
	
	output logic	   sign_flag_out,
	output logic	   extend_flag_out,
	output logic [6:0] cnt_out,
	output logic       cnt_wr
);
	logic        [6:0] counter;
	logic        [3:0] align_add, next_align_add;
	logic        [6:0] next_sign_en_cnt_out;
	logic              sign_en_reg;
	logic			   extend_en_reg;
	
	//counter
	always_ff @(posedge clk)
		if(~rst) counter <= 7'd0;
		else if(clk_en && sign_en)    counter <= sign_loc ? 7'd1 : advance ;
		else if(clk_en && counter[6]) counter <= align ? align_add : advance;
		else if(clk_en)               counter <= counter + (align? align_add : advance);
		else                          counter <= counter;
		
	//align_add
	always_comb begin
		next_align_add[2:0] = align_add[2:0] - advance[2:0];
		next_align_add[3] = ~|next_align_add[2:0];
	end
	
	always_ff @(posedge clk)
		if(~rst || (clk_en && align)) align_add <= 4'b1000;
		else if(clk_en)               align_add <= next_align_add;
		else                          align_add <= align_add;
		
	//sign_en_reg
	always_ff @(posedge clk)
		if(~rst)        sign_en_reg <= 1'b0;
		else if(clk_en) sign_en_reg <= (sign_en_reg && ~counter[6]) || sign_en;
		else            sign_en_reg <= sign_en_reg;
		
	//extend_en_reg
	always_ff @(posedge clk)
		if(~rst)		extend_en_reg <= 1'b0;
		else if(clk_en)	extend_en_reg <= (extend_en_reg && ~(counter[6] || sign_en)) || extend_en;
		else			extend_en_reg <= extend_en_reg;
		
		
	
	//sign_flag_out
	always_ff @(posedge clk)
		//if(~rst) cnt_out <= 8'h0;
		if(clk_en && (sign_en || counter[6])) sign_flag_out <= sign_en_reg;
		else                        		  sign_flag_out <= sign_flag_out;
		
	//extend_flag_out
	always_ff @(posedge clk)
		//if(~rst) cnt_out <= 8'h0;
		if(clk_en && (sign_en || counter[6])) extend_flag_out <= extend_en_reg;
		else                        		  extend_flag_out <= extend_flag_out;
	
	//cnt_out
	always_comb next_sign_en_cnt_out = sign_loc ? counter + advance - 1 : counter;
	always_ff @(posedge clk)
		//if(~rst) cnt_out <= 8'h0;
		if(clk_en && sign_en)         cnt_out <= next_sign_en_cnt_out ;
		else if(clk_en && counter[6]) cnt_out <= counter;
		else                          cnt_out <= cnt_out;
		
	//cnt_wr
	always_ff @(posedge clk)
		if(~rst)        cnt_wr <= 1'b0;
		else if(clk_en) cnt_wr <= sign_en || counter[6];
		else            cnt_wr <= 1'b0;
endmodule