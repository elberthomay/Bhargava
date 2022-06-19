module post_des_ser(
	input        clk, clk_en, rst,
	input [63:0] des_in,
	input        des_busy,
	input        des_wr,
	input [63:0] last_in,
	input [5:0]  last_size,
	input        last_filled,
	
	output logic last_ack,
	output logic sign_out,
	output logic sign_en
);
	logic [63:0] data;
	logic [6:0]  size;
	logic        data_empty;
	
	//data
	always_ff @(posedge clk)
		//if(~rst)                       data <= 64'h0;
		if(clk_en && des_wr)           data <= des_in;
		else if(clk_en && last_ack)    data <= last_in;
		else if(clk_en && ~data_empty) data <= {data[62:0], 1'b0};
		
	//size
	always_ff @(posedge clk)
		//if(~rst) size <= 7'd0;
		if(clk_en && des_wr)           size <= 7'd64;
		else if(clk_en && last_ack)    size <= last_size;
		else if(clk_en && ~data_empty) size <= size - 1;
		
	//data_empty
	always_ff @(posedge clk)
		if(~rst)                                 data_empty <= 1'b1;
		else if(clk_en && (des_wr || last_ack) ) data_empty <= 1'b0;
		else if(clk_en && size == 1)             data_empty <= 1'b1;
		else                                     data_empty <= data_empty;
		
	//last_ack
	always_ff @(posedge clk)
		if(~rst)                                                last_ack <= 1'b0;
		else if(clk_en && ~des_busy && ~des_wr && data_empty && //
		        last_filled && ~last_ack)                       last_ack <= 1'b1;
		else if(clk_en)                                         last_ack <= 1'b0;
		else                                                    last_ack <= last_ack;
		
	//sign_out
	always_ff @(posedge clk)
		//if(~rst) sign_out <= 1'b0;
		if(clk_en) sign_out <= data[63];
		else       sign_out <= sign_out;
		
	//sign_en
	always_ff @(posedge clk)
		if(~rst)        sign_en <= 1'b0;
		else if(clk_en) sign_en <= ~data_empty;
		else            sign_en <= sign_en;
	
	
endmodule