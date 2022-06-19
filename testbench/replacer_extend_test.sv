module replacer_extend_test();
	logic       clk, clk_en, rst;
	logic [7:0] vid_in, cnt_in;
	logic       vid_empty, cnt_empty;
	logic       last_sign_in;
	logic       out_afull;
	
	logic       vid_rd, cnt_rd; 
	logic [7:0] data_out; 
	logic       data_wr;
	
	initial out_afull = 1'b0;
	
	logic [0:25] vid_empty_test = {2'b11, 23'b0, 1'b1};
	
	logic [0:6][7:0] cnt_in_test = 
					{8'd64, 
					 8'd65,
					 {1'b1, 7'd7},
					 {1'b1, 7'd15},
					 8'd9,
					 8'd3,
					 {1'b1, 7'd21}
					};
					
	logic [0:11] cnt_empty_test = {4'hF, 7'b0, 1'b1};
	
	initial begin
		clk = 1'b0;
		clk_en = 1'b1;
		rst = 1'b0;
	end
	always #5 clk = ~clk;
	initial @(posedge clk) rst <= 1'b1;
	
	initial vid_in = 8'hFF;
	
	//cnt
	int cnt_pnt = 0;
	always @(posedge clk) 
		if(cnt_rd && ~cnt_empty && cnt_pnt < 7) begin
			cnt_in <= cnt_in_test[cnt_pnt];
			cnt_pnt++;
		end
		
	//vid_empty
	int vid_pnt = 0;
	initial vid_empty = 1'b1;
	always @(posedge clk) 
		if(vid_rd && vid_pnt < 26) begin
			vid_empty <= vid_empty_test[vid_pnt];
			vid_pnt++;
		end
	
	//cnt_empty
	initial cnt_empty = 1'b1;
	int cnt_empty_pnt = 0;
	always @(posedge clk)
		if(cnt_rd && cnt_empty_pnt < 12) begin
			cnt_empty <= cnt_empty_test[cnt_empty_pnt];
			cnt_empty_pnt++;
		end
	
	initial last_sign_in = 1'b1;
	
	
	
	replacer_extend ex(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst),
		
		.vid_in(vid_in), 
		.cnt_in(cnt_in),
		
		.vid_empty(vid_empty), 
		.cnt_empty(cnt_empty),
		
		.last_sign_in(last_sign_in),
		.out_afull(out_afull),
	
		.vid_rd(vid_rd), 
		.cnt_rd(cnt_rd), 
		
		.data_out(data_out), 
		.data_wr(data_wr)
	);

endmodule