module DES_single_test();
	reg clk, clk_en, rst;
	
	reg [63:0] data_in = 64'h85abcd1a98876543;	// 64'h4bbd010363a955c0
    reg [63:0] key_in = 64'ha1b2c3d4e5f61234;	//
	reg        mode_in = 1'b0;					// 1'b1
	
	reg        key_en;
	reg        data_en;
	
	wire [63:0] data_out;
	wire        des_busy;
	wire        des_wr;
   // #1
    //`ASSERT(OUT == 64'h4bbd010363a955c0)
	
	initial begin
		clk = 1'b0;
		rst = 1'b0;
		clk_en = 1'b1;
		
		key_en = 1'b0;
		data_en = 1'b0;
	end
	
	always #5 clk = ~clk;
	
	initial @(posedge clk) rst <= 1'b1;
	
	initial begin
		repeat(10) @(posedge clk);
		@(negedge des_busy) begin
			data_in = 64'h85abcd1b98876543;
		end
	end
	
	initial begin
		@(posedge clk) key_en = 1'b1;
		@(posedge clk) key_en = 1'b0;
	end
	
	initial begin
		repeat(4) @(posedge clk);
		@(posedge clk) data_en <= 1'b1;
		@(posedge clk) data_en <= 1'b0;
		
		@(negedge des_busy) data_en <= 1'b1;
		@(posedge clk) data_en <= 1'b0;
	end
	
	DES_single des(
		.clk(clk),  
		.clk_en(clk_en),  
		.rst(rst), 
		.data_in(data_in),  
		.data_en(data_en), 
		.key_in(key_in), 
		.mode_in(mode_in),  
		.key_en(key_en), 
		.data_out(data_out),
		.des_busy(des_busy), 
		.des_wr(des_wr)
	);
endmodule