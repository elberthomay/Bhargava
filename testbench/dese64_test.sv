module dese64_test();
	logic clk, clk_en, rst;
	logic sign_in;
	logic sign_wr;
	logic slice_end;
	logic last_ack;
	
	logic [0:63] sign_out;
	logic [6:0]  size_out;
	logic        des_wr;
	logic        last_wr;
	
	initial begin
		clk = 1'b0;
		clk_en = 1'b1;
		rst = 1'b0;
	end
	always #5 clk = ~clk;
	
	initial @(posedge clk) rst <= 1'b1;
	
	//always begin
	//	@(posedge clk);
	//	@(posedge clk) clk_en <= 1'b0;
	//	@(posedge clk) clk_en <= 1'b1;
	//end
	
	initial sign_in = 1'b1;
	always @(posedge clk)
		if(sign_wr) sign_in <= ~sign_in;
		
	initial begin
		sign_wr = 0;
		@(posedge clk);
		@(posedge clk) sign_wr <= 1'b1;
		repeat(90) @(posedge clk);
		@(posedge clk) sign_wr <= 1'b0;
		@(posedge clk) sign_wr <= 1'b1;
		repeat(63) @(posedge clk);
		@(posedge clk) sign_wr <= 1'b0;
	end
	
	initial begin
		slice_end = 1'b0;
		repeat(92) @(posedge clk);
		@(posedge clk) slice_end <= 1'b1;
		@(posedge clk) slice_end <= 1'b0;
		repeat(63) @(posedge clk);
		@(posedge clk) slice_end <= 1'b1;
		@(posedge clk) slice_end <= 1'b0;
	end
	
	always @(posedge clk)
		if(last_wr && ~last_ack) last_ack <= 1'b1;
		else                         last_ack <= 1'b0;
		
	dese64 deserializer(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst),
		.sign_in(sign_in),
		.sign_wr(sign_wr),
		.slice_end(slice_end),
		.last_ack(last_ack),
	
		.sign_out(sign_out),
		.size_out(size_out),
		.des_wr(des_wr),
		.last_wr(last_wr)
	);
endmodule