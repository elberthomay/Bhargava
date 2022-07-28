module splitter (
	clk, clk_en, rst, 
	stream_in, stream_empty, 
	stream_end_in,
	vid_afull, misc_afull, vbuf_afull,
	stream_out, stream_rd,
	stream_end_out,
	vid_wr, misc_wr);
	
	input            clk;
	input            clk_en;
	input            rst;				 // synchronous active low reset;
	
	input [7:0]      stream_in;			 // mpeg stream input
	input            stream_empty;	     // assert high if stream_in is valid;
	
	input            vid_afull;          // video fifo almost full
	input            misc_afull;         // misc fifo almost full
	input            vbuf_afull;         // vbuf fifo almost full
	
	input            stream_end_in;      // assert when stream end
	
	

	output reg [7:0] stream_out;         // mpeg stream output;
	output           stream_rd;
	
	output           vid_wr;             // video fifo write
	output           misc_wr;            // misc fifo write
	
	output reg       stream_end_out;
	
	reg              vid_out_en;         // video stream output enable
	reg              misc_out_en;        // non video stream output enable;

	reg              stream_ready;       // stream_in is valid;
	reg [15:0]       packet_counter;     // remaining bytes in packet;
	reg [7:0]        timestamp_counter;  // remaining timestamp byte;
	

	reg [7:0]        state;	             // state register;
	reg [7:0]        next;               // next state

	reg [23:0]       header_reg;         // store last three bytes
	
	reg              video_pack;
	
	wire             almost_full = vid_afull || misc_afull || vbuf_afull;
	
	wire             next_out_en = stream_ready && ~almost_full;
	

	parameter [7:0]
		STATE_NON_PACK                = 8'h0,
		STATE_PACK_SIZE               = 8'h1,
		STATE_PACK_SIZE1              = 8'h2,
		STATE_VIDEO_TIMESTAMP_HEADER  = 8'h3,
		STATE_VIDEO_MISC              = 8'h4,
		STATE_VIDEO_TIMESTAMP         = 8'h5,
		STATE_PACK_STREAM             = 8'h6;
		

	// next state logic
	always @* begin
		casez(state)
			STATE_NON_PACK               : next = (header_reg == 24'h000001 && stream_in >= 8'hBD && stream_in <= 8'hEF) ? STATE_PACK_SIZE : STATE_NON_PACK;     // 24'h000001 is header start code
				
			STATE_PACK_SIZE              : next = STATE_PACK_SIZE1;			                                       // first byte of pack size
			
			STATE_PACK_SIZE1             : next = video_pack ? STATE_VIDEO_TIMESTAMP_HEADER : STATE_PACK_STREAM;   // second byte of pack size, process timestamp if video, consume packet otherwise
			
			STATE_VIDEO_TIMESTAMP_HEADER : if( stream_in == 8'hFF )           next = STATE_VIDEO_TIMESTAMP_HEADER; // stuffing byte
                                           else if( stream_in[7:6] == 2'b01 ) next = STATE_VIDEO_MISC;			   // buffer scale/ size
                                           else if( stream_in[5:4] == 2'b00 ) next = STATE_PACK_STREAM;            // no timestamp, next byte is video stream
                                           else                               next = STATE_VIDEO_TIMESTAMP;        // timestamp
										   
			STATE_VIDEO_MISC             : next = STATE_VIDEO_TIMESTAMP_HEADER;                                    // skip buffer size
			
			STATE_VIDEO_TIMESTAMP        : if( timestamp_counter == 16'h1 )   next = STATE_PACK_STREAM;            // timestamp over, next byte is video stream
                                           else                               next = STATE_VIDEO_TIMESTAMP;        // timestamp bytes still remain
										   
			STATE_PACK_STREAM            : if( packet_counter == 16'h1 )      next = STATE_NON_PACK;                // packet over, back to STATE_NON_PACK
                                           else                               next = STATE_PACK_STREAM;             // packet remains
										   
			default                      : next = STATE_NON_PACK;                                                   // something is wrong
		endcase
	end
	
	// state
	always @(posedge clk)
		if(~rst)                       state <= STATE_NON_PACK;
		else if(clk_en && next_out_en) state <= next;
		else                           state <= state;
	
	always @(posedge clk)
		if(~rst)                                   video_pack <= 1'b0;
		else if(clk_en && state == STATE_NON_PACK) video_pack <= header_reg == 24'h000001 && stream_in[7:4] == 4'hE;
		else                                       video_pack <= video_pack;

	// stream_out
	always @(posedge clk)
		if(~rst)                       stream_out <= 8'h0;
		else if(clk_en && next_out_en) stream_out <= stream_in;
		else                           stream_out <= stream_out;
		
	
	//vid_out_en
	always @(posedge clk)
		if(~rst)        vid_out_en <= 1'b0;
		else if(clk_en) vid_out_en <= next_out_en && state == STATE_PACK_STREAM && video_pack;
		else            vid_out_en <= vid_out_en;
	
	//misc_out_en
	always @(posedge clk)
		if(~rst)        misc_out_en <= 1'b0;
		else if(clk_en) misc_out_en <= next_out_en && (state != STATE_PACK_STREAM || ~video_pack);
		else            misc_out_en <= misc_out_en;
	
	//stream_ready
	always @(posedge clk)
		if(~rst)        stream_ready <= 1'b0;
		else if(clk_en) stream_ready <= (stream_ready && ~next_out_en) || (stream_rd && ~stream_empty);
		else            stream_ready <= stream_ready;
		
	//stream_end_out
	always @(posedge clk)
		if(~rst)        stream_end_out <= 1'b0;
		else if(clk_en) stream_end_out <= stream_end_in && stream_empty && ~stream_ready;
		else            stream_end_out <= stream_end_out;
		
	assign vid_wr = vid_out_en && clk_en;
	assign misc_wr = misc_out_en && clk_en;
	assign stream_rd = clk_en && (~stream_ready || next_out_en);

	// header_reg
	always @(posedge clk) begin
		if(~rst)                       header_reg <= 24'hFFFFFF;
		else if(clk_en && next_out_en) header_reg <= { header_reg[15:0], stream_in };
		else                           header_reg <= header_reg;
	end
	
	// packet_counter
	always @(posedge clk) begin
		if(~rst)                                     packet_counter <= 16'h0;
		else if(clk_en && state == STATE_PACK_SIZE)  packet_counter <= {stream_in, packet_counter[7:0]};
		else if(clk_en && state == STATE_PACK_SIZE1) packet_counter <= {packet_counter[15:8], stream_in};
		else if(clk_en && next_out_en)               packet_counter <= packet_counter - 16'd1;
		else                                         packet_counter <= packet_counter;
	end
	
	// timestamp_counter
	always @(posedge clk) begin
		if(~rst)                                                                            timestamp_counter <= 8'h0;
		else if(clk_en && state == STATE_VIDEO_TIMESTAMP_HEADER && stream_in[5:4] == 2'b10) timestamp_counter <= 8'h4;
		else if(clk_en && state == STATE_VIDEO_TIMESTAMP_HEADER && stream_in[5:4] == 2'b11) timestamp_counter <= 8'h9;
		else if(clk_en && next_out_en )                                                     timestamp_counter <= timestamp_counter - 8'd1;
		else                                                                                timestamp_counter <= timestamp_counter;
	end
endmodule