/*
	create extend counter from advance_reg and align_reg.
	extend_en indicate existance of extend bit, advance would be 16, align deasserted,
	extend bit is on bit 7(xxxx_xxxx_exxx_xxxx),
	therefore next_counter will be 8, and cnt_out[6:0] is counter + 8
	
	
	
	cnt_out[7] indicate existance of extend bit at the first bit
	ex. {1'b1, 6'd5} : |xxxx
*/

module extend_counter(
	input              clk, clk_en, rst,
	input        [4:0] advance,
	input              align,
	input              extend_en,
	
	output logic [7:0] cnt_out,
	output logic       cnt_wr
);
	logic        [6:0] counter, next_extend_en_cnt_out;
	logic        [3:0] align_add, next_align_add;
	logic              extend_en_reg;
	
	//counter
	always_ff @(posedge clk)
		if(~rst) counter <= 7'd0;
		else if(clk_en && extend_en ) counter <= 7'd8 ;
		else if(clk_en && counter[6]) counter <= align ? align_add : advance ;
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
	
	//extend_en_reg
	always_ff @(posedge clk)
		if(~rst)        extend_en_reg <= 1'b0;
		else if(clk_en) extend_en_reg <= (extend_en_reg && ~counter[6]) || extend_en;
		else            extend_en_reg <= extend_en_reg;
		
	//cnt_out
	always_comb next_extend_en_cnt_out = counter + 8;
	always_ff @(posedge clk)
		//if(~rst) cnt_out <= 8'h0;
		if(clk_en && extend_en)       cnt_out <= {extend_en_reg, next_extend_en_cnt_out};
		else if(clk_en && counter[6]) cnt_out <= {extend_en_reg, counter};
		else                          cnt_out <= cnt_out;
		
	//cnt_wr
	always_ff @(posedge clk)
		if(~rst)        cnt_wr <= 1'b0;
		else if(clk_en) cnt_wr <= extend_en || counter[6];
		else            cnt_wr <= 1'b0;
endmodule