module post_des_ser_test();

	//des twice, last block full, last block 1, des, clk_en, 
	
	logic        clk, clk_en, rst;
	logic [63:0] des_in;
	logic        des_busy;
	logic        des_wr;
	logic [63:0] last_in;
	logic [5:0]  last_size;
	logic        last_filled;
	
	logic last_ack;
	logic sign_out;
	logic sign_en;
	
	initial begin
		
		clk_en = 1'b1;
		rst = 1'b0;
		#5 clk = 1'b0;
	end
	
	initial @(posedge clk) rst <= 1'b1;
	always #5 clk = ~clk;
	
	initial des_in = 64'haaaa_aaaa_aaaa_aaaa;
	
	initial begin
		des_wr = 1'b0;
		repeat(10) @(posedge clk);
		@(posedge clk) des_wr <= 1'b1;
		@(posedge clk) des_wr <= 1'b0;
		repeat(96) @(posedge clk);
		@(posedge clk) des_wr <= 1'b1;
		@(posedge clk) des_wr <= 1'b0;
		repeat(129) @(posedge clk);
		@(posedge clk) des_wr <= 1'b1;
		@(posedge clk) des_wr <= 1'b0;
	end
	
	initial begin
		des_busy = 1'b1;
		repeat(108) @(posedge clk);
		@(posedge clk) des_busy <= 1'b0;
		repeat(91) @(posedge clk);
		@(posedge clk) des_busy <= 1'b1;
		repeat(14)@(posedge clk);
		@(posedge clk) des_busy <= 1'b0;
	end
	
	initial last_in = 64'h5555_5555_5555_5555;
	
	initial begin 
		last_size = 7'd0;
		repeat(100) @(posedge clk);
		@(posedge clk) last_size <= 7'd63;
		repeat(150) @(posedge clk);
		@(posedge clk) last_size <= 7'd1;
		repeat(64) @(posedge clk);
		@(posedge clk) last_size <= 7'd30;
	end
	
	initial begin
		last_filled = 1'b0;
		repeat(100) @(posedge clk);
		@(posedge clk) last_filled <= 1'b1;
		repeat(150) @(posedge clk);
		@(posedge clk) last_filled <= 1'b1;
		repeat(64) @(posedge clk);
		@(posedge clk) last_filled <= 1'b1;
	end
	
	always @(posedge clk)
		if(last_ack) last_filled <= 1'b0;
	
	post_des_ser post_des_serializer(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst),
		.des_in(des_in),
		.des_busy(des_busy),
		.des_wr(des_wr),
		.last_in(last_in),
		.last_size(last_size),
		.last_filled(last_filled),
	
		.last_ack(last_ack),
		.sign_out(sign_out),
		.sign_en(sign_en)
	);
endmodule