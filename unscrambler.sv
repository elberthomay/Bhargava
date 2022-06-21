module unscrambler(
	input               clk, clk_en, rst,
	input               sign_in,
	input               sign_en,
	input [6:0]         pos_in,				//pos_in[6] indicate end of mb
	input               pos_empty,
	
	output logic        pos_rd,
	output logic [63:0] unscrambler_out,
	output logic [6:0]  unscrambler_size,
	output logic        unscrambler_wr
);
	//logic               pos_ready0;
	logic               pos_ready;
	logic [63:0]        unscrambler_reg;
	logic [6:0]         size_reg;
	logic               mb_end;
	
	/*
	
	//pos_ready0
	always_ff @(posedge clk)
		if(~rst)        pos_ready0 <= 1'b0;
		else if(clk_en) pos_ready0 <= (pos_rd && ~pos_empty) || (pos_ready0 && ~pos_rd);
		else            pos_ready0 <= pos_ready0;
	
	//pos_ready
	always_ff @(posedge clk)
		if(~rst)        pos_ready <= 1'b0;
		else if(clk_en) pos_ready <= (pos_rd && pos_ready0) || (pos_ready && ~sign_en);
		else            pos_ready <= pos_ready;
		
	*/
	
	//pos_ready
	always_ff @(posedge clk)
		if(~rst)        pos_ready <= 1'b0;
		else if(clk_en) pos_ready <= pos_rd || (pos_ready && ~sign_en);
		else            pos_ready <= pos_ready;
		
	//unscrambler_reg
	always_ff @(posedge clk)
		//if(~rst) unscrambler_reg <= 64'h0;
		if(clk_en && sign_en) unscrambler_reg[63 - pos_in[5:0]] <= sign_in;
		else                  unscrambler_reg <= unscrambler_reg;
			
	//size_reg
	always_ff @(posedge clk)
		if(~rst)                   size_reg <= 7'd0;
		else if(clk_en && mb_end)  size_reg <= {6'h0, sign_en};
		else if(clk_en && sign_en) size_reg <= size_reg + 1;
		else                       size_reg <= size_reg;
			
	//mb_end
	always_ff @(posedge clk)
		if(~rst) mb_end <= 1'b0;
		else if(clk_en) mb_end <= sign_en && pos_in[6];
		else            mb_end <= mb_end;
		
	//unscrambler_out
	always_ff @(posedge clk)
		//if(~rst)             unscrambler_out <= 64'h0;
		if(clk_en && mb_end) unscrambler_out <= unscrambler_reg;
		else                 unscrambler_out <= unscrambler_out;
		
	//unscrambler_size
	always_ff @(posedge clk)
		//if(~rst)             unscrambler_size <= 7'd0;
		if(clk_en && mb_end) unscrambler_size <= size_reg;
		else                 unscrambler_size <= unscrambler_size;
		
	//unscrambler_wr
	always_ff @(posedge clk)
		if(~rst)        unscrambler_wr <= 1'b0;
		else if(clk_en) unscrambler_wr <= mb_end;
		else            unscrambler_wr <= 1'b0;
			
	assign pos_rd = (~pos_ready || sign_en) && ~pos_empty && clk_en;
	
	

endmodule