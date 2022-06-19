module wrapper_test();
	integer status, fd;
	reg clk, rst, stream_valid;
    reg [7:0] stream_data;
	
	wire [7:0] vid_out, misc_out;
	wire vid_out_en, misc_out_en;

initial begin
    clk = 1'b0;
	rst = 1'b0;
	#15 rst = 1'b1;
end

always begin
    #10 clk = ~clk;
end

initial begin
   fd = $fopen("wrapper_test.dat", "rb");
   if (!fd) $error("could not read file");
end

always @(posedge clk) begin
    if(!$feof(fd)) begin
        status = $fgetc(fd);
        if(status == -1) begin
			stream_valid <= 1'b0;
		end
        else begin
			stream_data <= status[7:0];
			stream_valid <= 1'b1;
		end
    end
    else stream_valid <= 1'b0;
end

splitter splitter_test(
	.clk(clk), .rst(rst), 
	.stream_data(stream_data), .stream_valid(stream_valid), 
	.vid_out(vid_out), .misc_out(misc_out), 
	.vid_out_en(vid_out_en), .misc_out_en(misc_out_en));
endmodule