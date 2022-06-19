module mb_ser_test();
	logic         clk; 
	logic         clk_en; 
	logic         rst;
    
    logic        [0:63] sign_in;
    logic [0:63] [5:0]  pos_in;
    logic        [6:0]  size_in;
    logic               mb_empty;
	logic               slice_end;
    
    logic        sign_afull;
    logic        pos_afull;
    
    logic        mb_rd;
	logic        sign_out;
	logic [6:0]  pos_out;
    logic        mb_wr;
	logic        slice_end_out;
	
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
	
	initial sign_in = 64'hAAAA_AAAA_AAAA_AAAA;
	
	initial begin
		@(negedge mb_rd) pos_in = { 64{6'd0} };
		@(negedge mb_rd)begin 
			for(int i = 0; i < 64; i++)
				pos_in[i] = i;
		end
		@(negedge mb_rd)begin
			for(int i = 0; i < 64; i++)
				pos_in[i] = 63 - i;
		end
		
		@(negedge mb_rd)begin
			int a = 2;
			for(int i = 0; i < 64; i++)begin
				pos_in[i] = a;
				a = a + 3;
			end
		end
	end
	
	initial begin
		@(negedge mb_rd) size_in = 7'd1;
		@(negedge mb_rd) size_in = 7'd64;
		@(negedge mb_rd);
		@(negedge mb_rd) size_in = 17;
		@(negedge mb_rd) size_in = 5;
		@(negedge mb_rd) size_in = 0;
	end
	
	initial begin
		mb_empty = 1'b0;
		@(negedge mb_rd);
		@(negedge mb_rd);
		@(negedge mb_rd);
		@(negedge mb_rd);
		@(negedge mb_rd);
		@(negedge mb_rd) mb_empty = 1'b1;
	end
	
	initial begin
		@(negedge mb_rd) slice_end = 1'b0;
		@(negedge mb_rd);
		@(negedge mb_rd);
		@(negedge mb_rd) slice_end = 1'b1;
		@(negedge mb_rd);
		@(negedge mb_rd);
		@(negedge mb_rd) slice_end = 1'b0;
	end
	
	initial begin
		sign_afull = 1'b0;
		pos_afull = 1'b0;
	end
	
	int cnt3 = 0; 
	int cnt4 = 0;
	always @(posedge clk)begin
		if((mb_wr && cnt3 == 3) || sign_afull) cnt3 <= 0;
		else if(mb_wr)                         cnt3 <= cnt3 + 1;
		else                                   cnt3 <= cnt3;
	end
	
	always @(posedge clk)begin
		if((mb_wr && cnt4 == 4) || pos_afull) cnt4 <= 0;
		else if(mb_wr)                        cnt4 <= cnt4 + 1;
		else                                  cnt4 <= cnt4;
	end
	
	always @(posedge clk)begin
		if(cnt3 == 3)sign_afull <= 1'b1;
		else         sign_afull <= 1'b0;
		
		if(cnt4 == 4)pos_afull <= 1'b1;
		else         pos_afull <= 1'b0;
	end
	
	mb_ser serializer(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst),
    
		.sign_in(sign_in),
		.pos_in(pos_in),
		.size_in(size_in),
		.mb_empty(mb_empty),
		.slice_end(slice_end),
    
		.sign_afull(sign_afull),
		.pos_afull(pos_afull),
    
		.mb_rd(mb_rd),
		.sign_out(sign_out),
		.pos_out(pos_out),
		.mb_wr(mb_wr),
		.slice_end_out(slice_end_out)
	);
endmodule