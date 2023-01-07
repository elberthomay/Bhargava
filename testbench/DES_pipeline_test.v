//`undef DES
`define DES 1

`timescale 1ns/1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2022 08:07:08 PM
// Design Name: 
// Module Name: DES_pipeline_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DES_pipeline_test(

    );
	reg clk_en, rst_n;
	
	integer r, file, file_out, status;
	reg [7:0] mem[0:50000000];
	
	
	
	reg clk;
    
    reg process_finished;
	
	integer i;
	
	
	reg [0:63]  data_in;
	reg        data_in_en, stream_end;
	
	wire [0:63] data_out;
	wire       mpeg_rd;
	reg        data_out_en;
	wire       des_busy;
	integer in_cnt = 0;
	integer out_cnt = 0;
	
	
	
	initial data_in = 64'h00_00_00_00_00_00_00_00;
	initial data_in_en = 1'b0;
	initial stream_end = 1'b0;
    initial process_finished = 1'b0;

	//clk
	initial clk = 1'b1;
	always #15 clk = ~clk;
	
	//clk_en
	initial clk_en = 1'b1;
	
	`ifdef DES
	
	reg [63:0] key_in;
	reg        mode_in;
	reg        key_en;
	
	initial begin
		key_in = 64'ha1b2c3d4e5f61234;
		
		mode_in = 1'b1;
		
		key_en = 1'b0;
		#150 key_en = 1'b0;
		@(posedge clk) key_en = 1'b1;
		@(posedge clk) key_en = 1'b0;
	end
	`endif
	
	
	//rst_n
	initial begin
		 rst_n = 1'b0;
		#105 @(posedge clk);
		@(posedge clk) rst_n <= 1'b1;
	end
	
	//file
	initial begin
        //file = $fopen("dats/bjork.mpg", "rb");	//bjork_snippet5
		file = $fopen("dats/des_out.mpg", "rb");	//bjork_snippet5
		if (!file) begin
			$error("could not read file");
			$stop;
		end
		r = $fread(mem, file);
	end
	
	//data_in and data_in_en
	
	
	always @(posedge clk) begin
        for(i = 0 ;i < 8 && rst_n; ) begin
            if(in_cnt < r)begin	//47519745 7724 1494 1640
                data_in[i*8 +: 8] <= mem[in_cnt];
                in_cnt = in_cnt + 1;
                i = i + 1;
            end
            else begin
                stream_end = 1;
                break;
            end
		end
        data_in_en = i == 8;
	end
	
	
	//data_out_en
	initial begin
		//file_out = $fopen("dats/des_out.mpg", "wb");
        file_out = $fopen("dats/des_dec.mpg", "wb");
		if (!file_out) begin
			$error("could not open file");
			$stop;
		end
	end
	
	always @(posedge clk) begin
		if(data_out_en) begin
            for(integer j = 0; j < 8; j++) begin
                $fwrite(file_out, "%c", data_out[j*8 +: 8]);
                out_cnt = out_cnt + 1;
            end
		end
        else if(stream_end && ~des_busy && ~process_finished) begin
            for(integer j = 0; j < i; j=j+1) begin
                $fwrite(file_out, "%c", data_in[j*8 +: 8]);
                out_cnt = out_cnt + 1;
                if(out_cnt == in_cnt && out_cnt != 0) $fclose(file_out);
            end
            process_finished = 1'b1;
        end
	end
	
	DES_pipeline DES_pipeline_inst(
		.clk(clk),
		.clk_en(clk_en),
		.rst(rst_n),
        .data_in(data_in),
        .data_in_en(data_in_en),
		
		.key_in(key_in),
		.mode_in(mode_in),
		.key_en(key_en),
		
		.data_out(data_out),
        .data_out_en(data_out_en),
        .des_busy(des_busy)
	);
	
endmodule
