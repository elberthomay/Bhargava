module sign_switcher_test();

	logic       clk, clk_en, rst;
	
	logic[7:0]  sign_count;				// sign_count input{[7]:has_sign, [6:0]:count}
	logic       sign_count_empty; 			// empty flag of sign_count_fifo
	
	logic[90:0] mb_conf;					// number of sign on each group(13*7 bit) motion, selected g1, unselected g1, selected g2... unselected g6;
	logic[2:0]  first_group;				// first group with sign
	logic       has_one_group;				// there's only 1 group with sign in mb
	logic       mb_conf_empty;				// empty flag of mb_conf_fifo
	
	
	
	logic       count_out_afull; 			// almost_full flag of count_out
	
	logic       mb_conf_rd; 			// rd flag to mb_conf_fifo
	logic       sign_count_rd; 		// rd flag to sign_count_fifo
	logic [7:0] count_out; 			// count_out output
	logic       count_out_wr; 		// write flag to count_out_fifo
	
	parameter               sign_count_test_count = 14;
	logic [0:sign_count_test_count-1][7:0] sign_count_test = 
					{
					
						{1'b0, 7'd0}, 
						{1'b0, 7'd1}, 
						{1'b0, 7'd2}, 
						{1'b0, 7'd3}, 
						{1'b0, 7'd4}, 
					 
						{1'b1, 7'd6},
						{1'b1, 7'd7},
						{1'b1, 7'd8},
					 
						{1'b0, 7'd64},
						{1'b0, 7'd2},
						{1'b0, 7'd2},
						{1'b0, 7'd2},
						{1'b0, 7'd2},
					 
						{1'b1, 7'd16}
					};
					
	
					
	parameter mb_conf_test_count = 11;
	
	logic [0:mb_conf_test_count-1][90:0] mb_conf_test = 
					{
						{ 7'd1, {12{7'd0} } } , 
						{ {1{7'd0} }, 7'd1, {11{7'd0} } }, 
						{ {3{7'd0} }, 7'd1, {9{7'd0} } }, 
						{ {5{7'd0} }, 7'd1, {7{7'd0} } }, 
						{ {7{7'd0} }, 7'd1, {5{7'd0} } }, 
						{ {9{7'd0} }, 7'd1, {3{7'd0} } }, 
						{ {11{7'd0} }, 7'd1, {1{7'd0} } }, 
						
						{ 7'd4, {12{7'd0} } }, 
						{ 7'd2, {10{7'd0} }, 7'd10, 7'd0 }, 
						{ 7'd4, {6{ 7'd10, 7'd54} } }, 
						{ 7'd0, {4{ 7'd11, 7'd0} }, {2{ 7'd10, 7'd0} } }
					};
					
	logic [0:mb_conf_test_count-1][2:0] first_group_test = 
					{
					
						3'd0 , 
						3'd1, 
						3'd2, 
						3'd3, 
						3'd4, 
						3'd5, 
						3'd6, 
						
						3'd0, 
						3'd0, 
						3'd0, 
						3'd1
					};
					
	logic [0:mb_conf_test_count-1] has_one_group_test = {8'hFF, 3'b0};
	
	
	initial begin
		clk = 1'b0;
		clk_en = 1'b1;
		rst = 1'b0;
	end
	always #5 clk = ~clk;
	initial @(posedge clk) rst <= 1'b1;
	
	//sign_count
	initial sign_count = 8'b1_0000000;
	// int sign_count_pnt = 0;
	// always @(posedge clk) 
		// if(sign_count_rd && ~sign_count_empty && sign_count_pnt < sign_count_test_count) begin
			// sign_count <= sign_count_test[sign_count_pnt];
			
			// if(sign_count_pnt == sign_count_test_count-1) sign_count_pnt = 0;
			// else                   sign_count_pnt++;
		// end
		
	//sign_count_empty
	initial sign_count_empty = 1'b0;
	
	int mb_conf_pnt = 0;
	always @(posedge clk) 
		if(mb_conf_rd && ~mb_conf_empty && mb_conf_pnt < mb_conf_test_count) begin
			mb_conf <= mb_conf_test[mb_conf_pnt];
			first_group <= first_group_test[mb_conf_pnt];
			has_one_group <= has_one_group_test[mb_conf_pnt];
			
			mb_conf_pnt++;
		end
		
	//mb_conf_empty
	initial mb_conf_empty = 1'b0;
	always @(posedge clk) 
		if(mb_conf_rd) begin
			if(mb_conf_pnt < mb_conf_test_count) mb_conf_empty <= 1'b0;
			else                                 mb_conf_empty <= 1'b1;
		end
		
	initial count_out_afull = 1'b0;

	sign_switcher sw(
		.clk(clk), 
		.clk_en(clk_en), 
		.rst(rst),
	
		.mb_conf(mb_conf),
		.first_group(first_group),
		.has_one_group(has_one_group),
		.mb_conf_empty(mb_conf_empty),
	
		.sign_count(sign_count),
		.sign_count_empty(sign_count_empty),
	
		.count_out_afull(count_out_afull), 
	
		.mb_conf_rd(mb_conf_rd), 
		.sign_count_rd(sign_count_rd), 
		.count_out(count_out), 	
		.count_out_wr(count_out_wr)
	);
endmodule