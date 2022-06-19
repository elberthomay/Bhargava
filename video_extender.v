module video_extender(clk, clk_en, rst, stream_end, vbuf_in, vbuf_wr_in, vbuf_out, vbuf_wr_out);
	input 		clk, clk_en, rst;
	input		stream_end;
	
	input[7:0] 	vbuf_in;
	input 		vbuf_wr_in;
	
	output[7:0] vbuf_out;
	output 		vbuf_wr_out;
	
	
	reg[3:0] extend_count;
	
	parameter [1:0] 
		STATE_IDLE   = 2'd0,
		STATE_EXTEND = 2'd1,
		STATE_FINISH = 2'd2;
		
	reg [1:0] state, next;
	
	//next
	always @* begin
		casez(state)
			STATE_IDLE   : next = stream_end ? STATE_EXTEND : STATE_IDLE;
			STATE_EXTEND : next = extend_count == 4'hF ? STATE_FINISH : STATE_EXTEND;
			default      : next = STATE_FINISH;
		endcase
	end
	
	//state
	always @(posedge clk)
		if(~rst)        state <= STATE_IDLE;
		else if(clk_en) state <= next;
		else            state <= state;
	
	//extend_count
	always @(posedge clk) begin
		if(~rst)                                 extend_count <= 4'h0;
		else if(clk_en && state == STATE_EXTEND) extend_count <= extend_count + 4'd1;
		else                                     extend_count <= extend_count;
	end
	
	assign vbuf_wr_out = vbuf_wr_in || state == STATE_EXTEND;
	assign vbuf_out = state == STATE_EXTEND? 8'h0 : vbuf_in;
endmodule