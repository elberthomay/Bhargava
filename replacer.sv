module replacer(
	input              clk, clk_en, rst, 
    input [7:0]        vid_in,
	input			   sign_flag,
	input              extend_flag,
	input [6:0]        cnt_in, 
	input              vid_empty, cnt_empty,
	input              sign_in,
	input              sign_empty,
	input              out_afull,
	
	output logic       vid_rd, cnt_rd, sign_rd, 
	output logic [7:0] data_out, 
	output logic       data_wr
);
	logic       module_en;
	logic       vid_ready0, cnt_ready0, sign_ready0;
	logic       vid_ready, cnt_ready, sign_ready;
	
	logic [7:0] vid_reg;
	logic       vid_reg_ready;
	
	logic       has_sign;
    logic       has_extend_0, has_extend_1;
    logic       extend_bit;

	logic [6:0] cnt_reg;
	logic       cnt_reg_ready;
	
	logic [3:0] next_decrement;
	logic [2:0] pointer;
    logic [2:0] extend_pointer;
	
	logic       next_data_wr;
	logic       cnt_reg_use;
	
	/*
	//vid_ready0
	always_ff @(posedge clk)
		if(~rst)           vid_ready0 <= 1'b0;
		else if(module_en) vid_ready0 <= (vid_rd && ~vid_empty) || (vid_ready0 && ~vid_rd);
		else               vid_ready0 <= vid_ready0;
		
	//vid_ready
	always_ff @(posedge clk)
		if(~rst)           vid_ready <= 1'b0;
		else if(module_en) vid_ready <= (vid_rd && vid_ready0) || (vid_ready && vid_reg_ready && ~next_data_wr);
		else               vid_ready <= vid_ready;
	
	
	//cnt_ready0
	always_ff @(posedge clk)
		if(~rst)           cnt_ready0 <= 1'b0;
		else if(module_en) cnt_ready0 <= (cnt_rd && ~vid_empty) || (cnt_ready0 && ~cnt_rd);
		else               cnt_ready0 <= cnt_ready0;
		
	//cnt_ready
	always_ff @(posedge clk)
		if(~rst)           cnt_ready <= 1'b0;
		else if(module_en) cnt_ready <= (cnt_rd && cnt_ready0) || (cnt_ready && cnt_reg_ready && ~cnt_reg_use);
		else               cnt_ready <= cnt_ready;
		
	//sign_ready0
	always_ff @(posedge clk)
		if(~rst)           sign_ready0 <= 1'b0;
		else if(module_en) sign_ready0 <= (sign_rd && ~sign_empty) || (sign_ready0 && ~sign_rd);
		else               sign_ready0 <= sign_ready0;
		
	//sign_ready
	always_ff @(posedge clk)
		if(~rst)           sign_ready <= 1'b0;
		else if(module_en) sign_ready <= (sign_rd && sign_ready0) || (sign_ready && ~has_sign);
		else               sign_ready <= sign_ready;
		
	*/
	
	//vid_ready
	always_ff @(posedge clk)
		if(~rst)           vid_ready <= 1'b0;
		else if(module_en) vid_ready <= vid_rd || (vid_ready && vid_reg_ready && ~next_data_wr);
		else               vid_ready <= vid_ready;
	
	//cnt_ready
	always_ff @(posedge clk)
		if(~rst)           cnt_ready <= 1'b0;
		else if(module_en) cnt_ready <= cnt_rd || (cnt_ready && cnt_reg_ready && ~cnt_reg_use);
		else               cnt_ready <= cnt_ready;
	
	//sign_ready
	always_ff @(posedge clk)
		if(~rst)           sign_ready <= 1'b0;
		else if(module_en) sign_ready <= sign_rd || (sign_ready && ~(has_sign && cnt_reg_ready));
		else               sign_ready <= sign_ready;
	
	
		
	
		
	
	//vid_reg
	always_ff @(posedge clk)
		//if(~rst) vid_reg <= 8'h0;
		if(module_en && (~vid_reg_ready || next_data_wr) )            vid_reg <= vid_in;
		else if(module_en && cnt_reg_ready && has_sign && sign_ready) vid_reg[pointer] <= sign_in;
		else                                                          vid_reg <= vid_reg;
		
	//vid_reg_ready
	always_ff @(posedge clk)
		if(~rst)           vid_reg_ready <= 1'b0;
		else if(module_en) vid_reg_ready <= vid_ready || (vid_reg_ready && ~next_data_wr);
		else               vid_reg_ready <= vid_reg_ready;
		
		
	//has_sign
	always_ff @(posedge clk)
		if(~rst)                                               has_sign <= 1'b0;
		else if(module_en && (~cnt_reg_ready || cnt_reg_use) ) has_sign <= sign_flag;
		else if(module_en && sign_ready)                       has_sign <= 1'b0;
		else                                                   has_sign <= has_sign;
        
    //has_extend_0
	always_ff @(posedge clk)
		if(~rst)                                               has_extend_0 <= 1'b0;
		else if(module_en && (~cnt_reg_ready || cnt_reg_use) ) has_extend_0 <= extend_flag;
		else if(module_en && sign_ready)                       has_extend_0 <= 1'b0;
		else                                                   has_extend_0 <= has_extend_0;
        
    //has_extend_1
    always_ff @(posedge clk)
        if(~rst)           has_extend_1 <= 1'b0;
        else if(module_en) has_extend_1 <= has_extend_0 && sign_ready;
        else               has_extend_1 <= has_extend_1;
        
    //extend_bit
    always_ff @(posedge clk)
        if(~rst)                                         extend_bit <= 1'b0;
        else if(module_en && has_extend_0 && sign_ready) extend_bit <= ~sign_in;
        else                                             extend_bit <= extend_bit;
        
    //extend_pointer
    always_ff @(posedge clk)
        if(~rst)                                         extend_pointer <= 3'b0;
        else if(module_en && has_extend_0 && sign_ready) extend_pointer <= pointer;
        else                                             extend_pointer <= extend_pointer;
        
		
	//cnt_reg
	always_ff @(posedge clk)
		if(~rst)                                               cnt_reg <= 7'b0;
		else if(module_en && (~cnt_reg_ready || cnt_reg_use) ) cnt_reg <= cnt_in;
		else if(module_en && (~has_sign || sign_ready) )       cnt_reg <= cnt_reg - next_decrement;
		else                                                   cnt_reg <= cnt_reg;
		
	//cnt_reg_ready
	always_ff @(posedge clk)
		if(~rst)           cnt_reg_ready <= 1'b0;
		else if(module_en) cnt_reg_ready <= cnt_ready || (cnt_reg_ready && ~cnt_reg_use );
		else               cnt_reg_ready <= cnt_reg_ready;
		
	//next_decrement
	always_ff @(posedge clk)
		if(~rst || (module_en && next_data_wr) )                          next_decrement <= 4'd8;
		else if(module_en && cnt_reg_ready && (~has_sign || sign_ready) ) next_decrement <= next_decrement - cnt_reg;
		else                                                              next_decrement <= next_decrement;
	
	//pointer
	always_ff @(posedge clk)
		if(~rst || (module_en && next_data_wr) )                          pointer <= 3'd7;
		else if(module_en && cnt_reg_ready && (~has_sign || sign_ready) ) pointer <= pointer - cnt_reg;
		else                                                              pointer <= pointer;
		
	//data_out
	generate for(genvar i = 7; i >=0; i--)
		always_ff @(posedge clk)
			//if(~rst)                                                    data_out[i] <= 1'b0;
			if(module_en && next_data_wr && has_sign && pointer == i)                 data_out[i] <= sign_in;
            else if(module_en && next_data_wr && has_extend_1 && extend_pointer == i) data_out[i] <= extend_bit;
			else if(module_en && next_data_wr)                                        data_out[i] <= vid_reg[i];
			else                                                                      data_out[i] <= data_out[i];
	endgenerate
	
	//data_wr
	always_ff @(posedge clk)
		if(~rst)           data_wr <= 1'b0;
		else if(module_en) data_wr <= next_data_wr;
		else               data_wr <= 1'b0;
		
	assign module_en = clk_en && ~out_afull;
	assign next_data_wr = vid_reg_ready && cnt_reg_ready && cnt_reg >= next_decrement && (~has_sign || sign_ready);
	assign cnt_reg_use = cnt_reg <= next_decrement && (~has_sign || sign_ready );
		
	assign vid_rd = (~vid_ready || ~vid_reg_ready || next_data_wr) && ~vid_empty && module_en;
	assign cnt_rd = (~cnt_ready || ~cnt_reg_ready || cnt_reg_use) && ~cnt_empty && module_en;
	assign sign_rd = (~sign_ready || (has_sign && cnt_reg_ready)) && ~sign_empty && module_en;
		
endmodule