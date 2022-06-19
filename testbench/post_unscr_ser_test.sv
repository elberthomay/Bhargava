module post_unscr_ser_test();
	logic        clk, clk_en, rst;
	logic [63:0] data_in;
	logic [6:0]  size_in;
	logic        unscrambled_empty;
	
	logic        unscrambled_rd;
	logic        bit_out;
	logic        bit_wr;
	
	initial begin
		clk = 1'b0;
		clk_en = 1'b1;
		rst = 1'b0;
	end
	
	always #5 clk = ~clk;
	always @(posedge clk) clk_en <= ~clk_en;
	initial @(posedge clk) rst <= 1'b1;
	
	initial data_in = 64'haaaa_aaaa_aaaa_aaaa;
	
	initial begin
		@(negedge unscrambled_rd) size_in = 7'd64;
		@(negedge unscrambled_rd) size_in = 7'd1;
		@(negedge unscrambled_rd) size_in = 7'd30;
	end
	
	initial begin
		unscrambled_empty = 1'b0;
		repeat(2) @(negedge unscrambled_rd);
		@(negedge unscrambled_rd) unscrambled_empty = 1'b1;
	end
	
	post_unscr_ser post_unscrambler_serializer(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst),
		.data_in(data_in),
		.size_in(size_in),
		.unscrambled_empty(unscrambled_empty),
	
		.unscrambled_rd(unscrambled_rd),
		.bit_out(bit_out),
		.bit_wr(bit_wr)
	);

endmodule