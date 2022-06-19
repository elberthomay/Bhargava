module replacer_extend(
	input clk, clk_en, rst,
	input        [7:0] vid_in, cnt_in,
	input              vid_empty, cnt_empty,
	input              last_sign_in,
	input              out_afull,
	
	output logic       vid_rd, cnt_rd, 
	output logic [7:0] data_out, 
	output logic       data_wr
);
	logic module_en;
	
	//logic cnt_ready0;
	logic vid_ready, cnt_ready;
	logic cnt_reg_ready;
	
	logic has_extend;
	logic [6:0] cnt_reg;
	
	logic [3:0]next_decrement;
	logic [2:0]pointer;
	
	logic next_data_wr;
	logic cnt_reg_use;
	
	//data_out
	generate for(genvar i = 7; i >= 0; i--)
		always_ff @(posedge clk)
			//if(~rst) data_out[i] <= 1'b0;
			if(module_en && next_data_wr && has_extend && pointer == i) data_out[i] <= ~last_sign_in;
			else if(module_en && next_data_wr)                          data_out[i] <= vid_in[i];
			else                                                        data_out[i] <= data_out[i];
	endgenerate
	
	//data_wr
	always_ff @(posedge clk)
		if(~rst)           data_wr <= 1'b0;
		else if(module_en) data_wr <= next_data_wr;
		else               data_wr <= 1'b0;
	
	//vid_ready
	always_ff @(posedge clk)
		if(~rst)           vid_ready <= 1'b0;
		else if(module_en) vid_ready <= (vid_rd && ~vid_empty) || (vid_ready && ~next_data_wr);
		else               vid_ready <= 1'b0;
		
	/*
	//cnt_ready0
	always_ff @(posedge clk)
		if(~rst)           cnt_ready0 <= 1'b0;
		else if(module_en) cnt_ready0 <= (cnt_rd && ~cnt_empty) || (cnt_ready0 && ~cnt_rd);
		else               cnt_ready0 <= cnt_ready0;	
	
	//cnt_ready
	always_ff @(posedge clk)
		if(~rst)           cnt_ready <= 1'b0;
		else if(module_en) cnt_ready <= (cnt_rd && cnt_ready0) || (cnt_ready && cnt_reg_ready && ~cnt_reg_use);
		else               cnt_ready <= cnt_ready;
		
	*/
	
	//cnt_ready
	always_ff @(posedge clk)
		if(~rst)           cnt_ready <= 1'b0;
		else if(module_en) cnt_ready <= cnt_rd || (cnt_ready && cnt_reg_ready && ~cnt_reg_use);
		else               cnt_ready <= cnt_ready;
		
	//cnt_reg_ready
	always_ff @(posedge clk)
		if(~rst)           cnt_reg_ready <= 1'b0;
		else if(module_en) cnt_reg_ready <= cnt_ready || (cnt_reg_ready && ~cnt_reg_use);
		else               cnt_reg_ready <= cnt_reg_ready;
		
	//has_extend
	always_ff @(posedge clk)
		//if(~rst) has_extend <= 1'b0;
		if(module_en && (~cnt_reg_ready || cnt_reg_use) ) has_extend <= cnt_in[7];
		else if(module_en)                                has_extend <= 1'b0;
		else                                              has_extend <= has_extend;
		
	//cnt_reg
	always_ff @(posedge clk)
		//if(~rst) cnt_reg <= 8'h0;
		if(module_en && (~cnt_reg_ready || cnt_reg_use) ) cnt_reg <= cnt_in[6:0];
		else if(module_en && vid_ready && cnt_reg_ready)  cnt_reg <= cnt_reg - next_decrement;
		else                                              cnt_reg <= cnt_reg;
		
	
	//next_decrement
	always_ff @(posedge clk)
		if(~rst || (module_en && next_data_wr) )         next_decrement <= 4'd8;
		else if(module_en && vid_ready && cnt_reg_ready) next_decrement <= next_decrement - cnt_reg;
		else                                             next_decrement <= next_decrement;
		
	//pointer
	always_ff @(posedge clk)
		if(~rst || (module_en && next_data_wr) )         pointer <= 3'd7;
		else if(module_en && vid_ready && cnt_reg_ready) pointer <= pointer - cnt_reg;
		else                                             pointer <= pointer;
	
	//module_en
	assign module_en = clk_en && ~out_afull;
	
	//next_data_wr
	assign next_data_wr = vid_ready && cnt_reg_ready && cnt_reg >= next_decrement;
	
	//cnt_reg_use
	assign cnt_reg_use = cnt_reg <= next_decrement;
	
	//vid_rd
	assign vid_rd = (~vid_ready || next_data_wr) && module_en;

	//cnt_rd
	assign cnt_rd = (~cnt_ready || ~cnt_reg_ready || cnt_reg_use) && ~cnt_empty && module_en;
	
endmodule