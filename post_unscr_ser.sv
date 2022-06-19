module post_unscr_ser(
	input clk, clk_en, rst,
	input [63:0] data_in,
	input [6:0]  size_in,
	input        unscrambled_empty,
	
	output logic unscrambled_rd,
	output logic bit_out,
	output logic bit_wr
);
	logic        unscrambled_ready;
	logic        reg_ready;
	logic [63:0] data_reg;
	logic [6:0]  size_reg;
	
	//unscrambled_ready
	always_ff @(posedge clk)
		if(~rst)        unscrambled_ready <= 1'b0;
		else if(clk_en) unscrambled_ready <= (unscrambled_rd && ~unscrambled_empty) || (unscrambled_ready && reg_ready);
		else            unscrambled_ready <= unscrambled_ready;
		
	//reg_ready
	always_ff @(posedge clk)
		if(~rst) reg_ready <= 1'b0;
		else if(clk_en) reg_ready <= (~reg_ready && unscrambled_ready) || (reg_ready && size_reg != 7'd1);
		else            reg_ready <= reg_ready;
		
	//data_reg
	always_ff @(posedge clk)
		//if(~rst) data_reg <= 64'h0;
		if(clk_en && unscrambled_ready && ~reg_ready) data_reg <= data_in;
		else if(clk_en && reg_ready)                  data_reg <= {data_reg[62:0], 1'b0};
		else                                          data_reg <= data_reg;
		
	//size_reg
	always_ff @(posedge clk)
		//if(~rst) size_reg <= 7'h0;
		if(clk_en && unscrambled_ready && ~reg_ready) size_reg <= size_in;
		else if(clk_en && reg_ready)                  size_reg <= size_reg - 1;
		else                                          size_reg <= size_reg;
		
	//unscrambled_rd
	assign unscrambled_rd = ~unscrambled_ready && clk_en;
	
	//bit_out
	always_ff @(posedge clk)
		//if(~rst) bit_out <= 1'b0;
		if(clk_en && reg_ready) bit_out <= data_reg[63];
		
	//bit_wr
	always_ff @(posedge clk)
		if(~rst)        bit_wr <= 1'b0;
		else if(clk_en) bit_wr <= reg_ready;
		else            bit_wr <= 1'b0;
endmodule