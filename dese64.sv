module dese64(
	input 				clk, clk_en, rst,
	input 				sign_in,			// sign input from mb_ser
	input 				sign_wr,			// sign input enable
	input 				slice_end,			// asserted when slice ended
	input 				last_ack,			// acknowledge flag for last_wr
	
	output logic [63:0] sign_out,			// sign output, 64 bit wide if des_wr is asserted, size_out wide otherwise
	output logic [5:0]  size_out,			// size of sign_out when last_wr is asserted
	output logic        des_wr,				
	output logic        last_wr
);
	logic [63:0] sign_reg;
	logic [5:0]  size_reg;
	logic [63:0] wr_ptr;					// one hot, next write position on sign_reg
	logic        was_full;					// sign_reg full
	
	//sign_reg
	generate for(genvar i=0; i<64; i++)
		always_ff @(posedge clk)
			//if(~rst) sign_reg[i] <= 1'h0;
			if(clk_en && sign_wr && wr_ptr[i]) sign_reg[i] <= sign_in;
			else                               sign_reg[i] <= sign_reg[i];
	endgenerate
	
	//size_reg
	always_ff @(posedge clk)
		if(~rst || (clk_en && slice_end) ) size_reg <= 6'd0;
		else if(clk_en && sign_wr)         size_reg <= size_reg + 1;
		else                               size_reg <= size_reg;
		
	//wr_ptr
	always_ff @(posedge clk)
		if(~rst || (clk_en && slice_end) ) wr_ptr <= {1'b1, 63'b0};
		else if(clk_en && sign_wr)         wr_ptr <= {wr_ptr[0], wr_ptr[63:1]};
		else                               wr_ptr <= wr_ptr;
		
	//was_full
	always_ff @(posedge clk)
		if(~rst)        was_full <= 1'b0;
		else if(clk_en) was_full <= wr_ptr[0] && sign_wr;
		else            was_full <= was_full;
		
	//sign_out
	always_ff @(posedge clk)
		//if(~rst) sign_out <= 64'h0;
		if(clk_en && (was_full || slice_end ) ) sign_out <= sign_reg;
		else                                    sign_out <= sign_out;
		
	//size_out
	always_ff @(posedge clk)
		//if(~rst) size_out <= 7'h0;
		if(clk_en && slice_end) size_out <= size_reg;
		else                    size_out <= size_out;
		
	//des_wr
	always_ff @(posedge clk)
		if(~rst)        des_wr <= 1'b0;
		else if(clk_en) des_wr <= was_full;
		else            des_wr <= des_wr;
		
	//last_wr
	always_ff @(posedge clk)
		if(~rst) last_wr <= 1'b0;
		else if(clk_en && slice_end && ~wr_ptr[63]) last_wr <= 1'b1;
		else if(clk_en && last_ack)                 last_wr <= 1'b0;
		else                                        last_wr <= last_wr;
endmodule