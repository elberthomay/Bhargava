module joiner (
	clk, clk_en, rst, 
	vid_in, vid_empty,
	misc_in, misc_empty,
	vid_rd, misc_rd, mpeg_out, mpeg_wr);
	
	input clk;
	input clk_en;
	input rst;								// synchronous active low reset;
	
	input      [7:0] vid_in;					// mpeg stream output
	input            vid_empty;						// assert high if stream_out is valid;
	
	input      [7:0] misc_in;					// mpeg stream output
	input            misc_empty;						// assert high if stream_out is valid;

	output           vid_rd;
	output           misc_rd;
	
	output reg [7:0] mpeg_out;					// video stream output enable
	output reg       mpeg_wr;
	
	/*
	input [7:0] stream_in;					// mpeg stream input
	input stream_valid;						// assert high if stream_in is valid;

	output reg [7:0] stream_out;			// mpeg stream output;
	
	output reg vid_out_en;					// video stream output enable
	output reg misc_out_en;					// non video stream output enable;
	*/

	
	reg              vid_ready;
	reg              misc_ready;


	reg [15:0] packet_counter;				// remaining bytes in packet;
	reg [7:0] timestamp_counter;			// remaining timestamp byte;

	reg [7:0] state;							// state register;
	reg [7:0] next;							// next state

	reg [23:0] header_reg;					// store last three bytes
	

	parameter [7:0]
		STATE_NON_PACK						= 8'h0,
		STATE_NON_VIDEO_SIZE0			= 8'h1,
		STATE_NON_VIDEO_SIZE1			= 8'h2,
		STATE_NON_VIDEO_STREAM			= 8'h3,
		STATE_VIDEO_SIZE0					= 8'h4,
		STATE_VIDEO_SIZE1					= 8'h5,
		STATE_VIDEO_MISC					= 8'h6,
		STATE_VIDEO_TIMESTAMP_HEADER	= 8'h7,
		STATE_VIDEO_TIMESTAMP			= 8'h8,
		STATE_VIDEO_STREAM				= 8'h9;

	// next state logic
	always @* begin
		casez(state)
			STATE_NON_PACK						: 
				if( header_reg == 24'h000001 ) begin
					if( misc_in[7:4] == 4'hE ) 	next = STATE_VIDEO_SIZE0;				// E0~EF video pack
					else if ( misc_in == 8'hBA )	next = STATE_NON_VIDEO_STREAM;		// pack header treated as "pack" 8 bytes long
					else next = STATE_NON_VIDEO_SIZE0;												// other packs
				end 
				else next = STATE_NON_PACK;															// something is wrong
				
			STATE_NON_VIDEO_SIZE0			: next = STATE_NON_VIDEO_SIZE1;					// first byte of non-video pack size
			STATE_NON_VIDEO_SIZE1			: next = STATE_NON_VIDEO_STREAM;					// second byte of non- video pack size
			STATE_NON_VIDEO_STREAM			:
				if( packet_counter != 16'h1 ) next = STATE_NON_VIDEO_STREAM;					// non-video pack remains
				else next = STATE_NON_PACK;															// non-video pack ran out, back to state_non_pack
			STATE_VIDEO_SIZE0					: next = STATE_VIDEO_SIZE1;						// first byte of video pack size
			STATE_VIDEO_SIZE1					: next = STATE_VIDEO_TIMESTAMP_HEADER;			// second byte of video pack size
			STATE_VIDEO_MISC					: next = STATE_VIDEO_TIMESTAMP_HEADER;			// skip buffer size
			STATE_VIDEO_TIMESTAMP_HEADER	: 
				if( misc_in == 8'hFF ) next = STATE_VIDEO_TIMESTAMP_HEADER;			// stuffing byte
				else if( misc_in[7:6] == 2'b01 ) next = STATE_VIDEO_MISC;				// buffer scale/ size
				else if( misc_in[5:4] == 2'b00 ) next = STATE_VIDEO_STREAM;			// no timestamp, next byte is video stream
				else next = STATE_VIDEO_TIMESTAMP;													// timestamp
			STATE_VIDEO_TIMESTAMP			:
				if( timestamp_counter > 16'h1 ) next = STATE_VIDEO_TIMESTAMP;				// timestamp bytes still remain
				else next = STATE_VIDEO_STREAM;														// timestamp over, next byte is video stream
			STATE_VIDEO_STREAM				: 
				if( packet_counter != 16'h1 ) next = STATE_VIDEO_STREAM;						// video pack remains
				else next = STATE_NON_PACK;															// video pack ran out, back to state_non_pack
			default								: next = STATE_NON_PACK;								// something is wrong
		endcase
	end
	
	wire next_mpeg_wr = (state == STATE_VIDEO_STREAM)? vid_ready : misc_ready;
	// state
	always @(posedge clk) begin
		if(~rst)                        state <= STATE_NON_PACK;
		else if(clk_en && next_mpeg_wr) state <= next;
		else                            state <= state;
	end
	
	wire [7:0] next_mpeg_out = (state == STATE_VIDEO_STREAM)? vid_in : misc_in;

	//mpeg_out
	always @(posedge clk)
		if(clk_en) mpeg_out <= next_mpeg_out;
		else       mpeg_out <= mpeg_out;
		
	//mpeg_wr
	always @(posedge clk)
		if(~rst)        mpeg_wr <= 1'b0;
		else if(clk_en) mpeg_wr <= next_mpeg_wr;
		else            mpeg_wr <= mpeg_wr;
		
	//vid_ready
	always @(posedge clk)
		if(~rst)        vid_ready <= 1'b0;
		else if(clk_en) vid_ready <= (vid_ready && state != STATE_VIDEO_STREAM) || (vid_rd && ~vid_empty);
		else            vid_ready <= vid_ready;
	
	//misc_ready
	always @(posedge clk)
		if(~rst)        misc_ready <= 1'b0;
		else if(clk_en) misc_ready <= (misc_ready && state == STATE_VIDEO_STREAM) || (misc_rd && ~misc_empty);
		else            misc_ready <= misc_ready;
	
	//vid_rd
	assign vid_rd = ~vid_ready || state == STATE_VIDEO_STREAM;
		
	//misc_rd
	assign misc_rd = ~misc_ready || state != STATE_VIDEO_STREAM;

	// header_reg
	always @(posedge clk) begin
		if(~rst) header_reg <= 24'hFFFFFF;
		else if (next_mpeg_wr) header_reg <= { header_reg[15:0], next_mpeg_out };
		else header_reg <= header_reg;
	end
	
	// state works
	
	// packet_counter
	always @(posedge clk) begin
		if(~rst) packet_counter <= 16'h0;
		else if(next_mpeg_wr) begin
		    casez(state)
		       STATE_NON_PACK                              : if( header_reg == 24'h000001 && misc_in == 8'hBA) packet_counter <= 16'h8;
    		    STATE_NON_VIDEO_SIZE0, STATE_VIDEO_SIZE0    : packet_counter[15:8] <= misc_in;
    		    STATE_NON_VIDEO_SIZE1, STATE_VIDEO_SIZE1    : packet_counter[7:0] <= misc_in;
				default										: packet_counter <= packet_counter - 1;
		    endcase
		end
		else packet_counter <= packet_counter;
	end
	
	// timestamp_counter
	always @(posedge clk) begin
		if(~rst) timestamp_counter <= 8'h0;
		else if(next_mpeg_wr) begin
		    if ( state == STATE_VIDEO_TIMESTAMP_HEADER && misc_in[7:6] == 2'b00 ) begin
			    casez(misc_in[5:4])
				    2'b10 : timestamp_counter <= 8'h4;
				    2'b11 : timestamp_counter <= 8'h9;
				    default : timestamp_counter <= 8'h0;
			    endcase
		    end
		    else if ( state == STATE_VIDEO_TIMESTAMP ) timestamp_counter <= timestamp_counter - 1;
		    else timestamp_counter <= timestamp_counter;
		end
		else timestamp_counter <= timestamp_counter;
	end
endmodule