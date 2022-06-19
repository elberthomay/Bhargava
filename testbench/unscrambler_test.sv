module unscrambler_test();
	logic               clk, clk_en, rst;
	logic               sign_in;
	logic               sign_en;
	logic [6:0]         pos_in;				//pos_in[6] indicate end of mb
	logic               pos_empty;
	
	logic        pos_rd;
	logic [63:0] unscrambler_out;
	logic [6:0]  unscrambler_size;
	logic        unscrambler_wr;
	
	logic [63:0]testbit = 64'b111111_000000_111111_000000_111111_000000_111111_000000_111111_000000_1111;
	logic [63:0][6:0] test_pos= {1'b1,6'd0, 7'd11, 7'd22, 7'd33, 7'd44, 7'd54, 
								 7'd1, 7'd12,7'd23,7'd34,7'd45,7'd55,
								 7'd2,7'd13,7'd24,7'd35,7'd46,7'd56,
								 7'd3,7'd14,7'd25,7'd36,7'd47,7'd57,
								 7'd4, 7'd15,7'd26,7'd37,7'd48,7'd58,
						 		 7'd5,7'd16,7'd27,7'd38,7'd49,7'd59,
						 		 7'd6,7'd17,7'd28,7'd39,7'd50,7'd60,
						 		 7'd7,7'd18,7'd29,7'd40,7'd51,7'd61,
						 		 7'd8,7'd19,7'd30,7'd41,7'd52,7'd62,
						 		 7'd9,7'd20,7'd31,7'd42,7'd53,7'd63,
						 		 7'd10,7'd21,7'd32,  1'b1,6'd43};
	
	int pos_cnt = 63;
	always @(posedge clk)
		if(pos_rd) begin
			pos_in <= test_pos[pos_cnt];
			pos_cnt--;
		end
	
	initial pos_empty = 1'b0;
	always @(posedge clk)
		if(pos_rd && pos_cnt == 0) pos_empty <= 1'b1;
		
	initial sign_en = 1'b0;
	
	initial begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk)sign_en = 1'b1;
		repeat(63) @(posedge clk);
		@(posedge clk) sign_en = 1'b0;
	end
	
	int bit_cnt = 62;
	
	initial begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk)sign_in = 1'b1;
	end
	
	always @(posedge clk)
		if(sign_en == 1) begin
			sign_in <= testbit[bit_cnt];
			bit_cnt--;
		end
	
	initial begin
		clk = 1'b0;
		rst = 1'b0;
		clk_en = 1'b1;
	end
	
	always #5 clk = ~clk;
	
	initial @(posedge clk) rst <= 1'b1;
	
	unscrambler unscr(
		.clk(clk), .clk_en(clk_en), .rst(rst),
		.sign_in(sign_in),
		.sign_en(sign_en),
		.pos_in(pos_in),				//pos_in[6] indicate end of mb
		.pos_empty(pos_empty),
	
		.pos_rd(pos_rd),
		.unscrambler_out(unscrambler_out),
		.unscrambler_size(unscrambler_size),
		.unscrambler_wr(unscrambler_wr)
	);
	
endmodule