module replacer_sign_test();
	logic       clk, clk_en, rst; 
	logic [7:0] vid_in, cnt_in; 
	logic       vid_empty, cnt_empty;
	logic       sign_in;
	logic       sign_empty;
	logic       out_afull;
	
	logic       vid_rd, cnt_rd, sign_rd; 
	logic [7:0] data_out; 
	logic       data_wr; 
	logic       last_sign_out;
	
	/* test
		no vid
		is vid, no cnt
		is vid, is cnt no sign
		
		64 no sign
		
		110 no sign
		2 sign
		
		78 sign
		1 sign
		1 sign
		
		2 no
		2 sign
		2 sign
		2 sign
		
		4 nosign
		4 sign
		
		16 nosign
	*/
	logic [0:37] vid_empty_test = {2'b1, 35'b0, 1'b1};
	
	logic [0:12][7:0] cnt_in_test = 
					{8'd64, 
					
					 8'd110, 
					 {1'b1, 7'd2}, 
					 
					 {1'b1, 7'd78},
					 {1'b1, 7'd1},
					 {1'b1, 7'd1},
					 
					 {1'b0, 7'd2},
					 {1'b1, 7'd2},
					 {1'b1, 7'd2},
					 {1'b1, 7'd2},
					 
					 {1'b0, 7'd4},
					 {1'b1, 7'd4},
					 
					 {1'b0, 7'd16}
					};
					 
	logic [0:16] cnt_empty_test = {3'hF, 13'b0, 1'b1};
	
	logic [0:14] sign_empty_test = {6'hFF, 8'b0, 1'b1};
	
	initial begin
		clk = 1'b0;
		clk_en = 1'b1;
		rst = 1'b0;
	end
	
	initial out_afull = 1'b0;
	
	always #5 clk = ~clk;
	initial @(posedge clk) rst <= 1'b1;
	
	initial vid_in = 8'hFF;
	
	//vid_empty
	int data_pnt = 0;
	initial vid_empty = 1'b1;
	always @(posedge clk) 
		if(vid_rd && data_pnt < 38) begin
			vid_empty <= vid_empty_test[data_pnt];
			data_pnt++;
		end
	
		
	//cnt
	int cnt_pnt = 0;
	initial cnt_empty = 1'b1;
	always @(posedge clk) 
		if(cnt_rd && ~cnt_empty && cnt_pnt < 13) begin
			cnt_in <= cnt_in_test[cnt_pnt];
			cnt_pnt++;
		end
	
	int cnt_empty_pnt = 0;
	always @(posedge clk)
		if(cnt_rd && cnt_empty_pnt < 17) begin
			cnt_empty <= cnt_empty_test[cnt_empty_pnt];
			cnt_empty_pnt++;
		end
	
		
	initial sign_in = 1'b0;
	
	initial sign_empty = 1'b1;
	int sign_pnt = 0;
	always @(posedge clk) 
		if(sign_rd && sign_pnt < 15) begin
			sign_empty <= sign_empty_test[sign_pnt];
			sign_pnt++;
		end
	
	
	replacer_sign rep(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst), 
		.vid_in(vid_in), 
		.cnt_in(cnt_in), 
		.vid_empty(vid_empty), 
		.cnt_empty(cnt_empty),
		.sign_in(sign_in),
		.sign_empty(sign_empty),
		.out_afull(out_afull),
	
		.vid_rd(vid_rd), 
		.cnt_rd(cnt_rd), 
		.sign_rd(sign_rd), 
		.data_out(data_out), 
		.data_wr(data_wr), 
		.last_sign_out(last_sign_out)
	);
endmodule