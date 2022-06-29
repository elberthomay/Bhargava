module video_test();

	integer status, fd, i;
	reg clk, rst, clk_en;
	reg vid_in_empty;
	reg [63:0] vid_in;

	wire vid_in_rd_en, signbit, getbits_valid;
	wire [23:0] getbits;
	wire [4:0] advance;
	wire [4:0] advance_reg;
	wire  group_change;
	wire align, align_reg, wait_state, vld_en;
    wire sign_loc, extend_en, sign_bit, sign_en, macroblock_end, slice_end;
	
	integer rld_cnt;
	
	reg mb_fifo_afull;

	task refresh_getbits(); 
		begin
			if(!$feof(fd)) begin
				for(i = 8; i >= 1; i = i - 1) begin
					if(!$feof(fd)) begin
        				status = $fgetc(fd);
        				if(status == -1) begin
							vid_in[i*8-1 -: 8] <= 8'h0;
						end
        				else begin
							vid_in[i*8-1 -: 8] <= status[7:0];
						end
					end
					else vid_in[i*8-1 -: 8] <= 8'h0;
					
				end
				vid_in_empty <= 1'b0;
    		end
    		else begin 
				vid_in_empty <= 1'b1;
			end
		end
	endtask

	initial begin
    	fd = $fopen("F:/Bhargava/Bhargava.srcs/src/testbench/dats/vld test.mpg", "rb");
    	if (!fd) $error("could not read file");
	end

	initial begin
		clk = 1'b0;
		rst = 1'b0;
		clk_en = 1'b1;
		
	end

	always begin
		#5 clk = ~clk;
	end

	initial @(posedge clk) rst <= 1'b1;	
	
	initial mb_fifo_afull = 1'b0;
	
	// initial rld_cnt = 0;
	// always @(posedge clk) begin
		// if(rld_cnt == 3) begin
			// mb_fifo_afull <= 1'b1;
			// rld_cnt <= 0;
		// end
		// else begin
			// mb_fifo_afull <= 1'b0;
			// rld_cnt <= rld_cnt + 1;
		// end
	// end

	initial vid_in_empty <= 1'b0;
	
	always @(posedge clk) begin
		if(vid_in_rd_en) refresh_getbits();
		//else vid_in_rd_valid <= 1'b0;
	end
	

	getbits fifo(
    .clk(clk), 
    .clk_en(clk_en), 
    .rst(rst), 
   	.vid_in(vid_in), 
    .vid_in_rd_en(vid_in_rd_en), 
    .vid_in_empty(vid_in_empty),
    .advance(advance), 
    .align(align),
    .getbits(getbits), 
    //.signbit(signbit), 
    .getbits_valid(getbits_valid),
    //.wait_state(wait_state), 
    .mb_fifo_afull(mb_fifo_afull), 
    .sign_counter_fifo_afull(1'b0), 
    .mb_conf_fifo_afull(1'b0), 
	.extend_counter_fifo_afull(1'b0),
    .vld_en(vld_en));

	video vld(
	.clk(clk),
	.clk_en(clk_en),
	.vld_en(vld_en),
	.rst(rst), 
	.getbits(getbits),
	.advance(advance), 
	.align(align), 
	.advance_reg(advance_reg), 
    .align_reg(align_reg),
	//.wait_state(wait_state),
	.sign_loc(sign_loc), 
	.extend_en(extend_en), 
	.group_change(group_change), 
	.sign_bit(sign_bit),
	.sign_en(sign_en), 
	.macroblock_end(macroblock_end), 
	.slice_end(slice_end)
	);
endmodule
