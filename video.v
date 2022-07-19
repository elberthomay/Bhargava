`undef DEBUG
//`define DEBUG 1

module video(
	clk, clk_en, vld_en, rst, getbits,
	advance, advance_reg, align, align_reg, //wait_state,
	sign_loc, extend_en, 
	group_change, sign_bit, sign_en, 
	macroblock_end, slice_end
);

	input 			  clk;
	input 			  clk_en;
	input             vld_en;
	input 			  rst;
	
	input	    [23:0]getbits;
	
	output reg   [4:0]advance;
	output reg   [4:0]advance_reg;
	output            align;
	output reg		  align_reg;
	//output 			  wait_state;

	output reg 		  sign_en;
	output reg 		  sign_loc;	//0 : front 1 : back;
	output reg 		  extend_en;
	
	output reg        group_change;
	output reg		  sign_bit;
	output reg		  macroblock_end;
	output reg		  slice_end;

	reg          [5:0]state;
  	reg          [5:0]next;

	wire              module_en;
	
	wire              next_sign_en;
	wire              next_extend_en;
	reg               next_sign_loc;
	wire         [4:0]sign_offset;

  	reg          [5:0]cnt; // counter used when loading quant matrices
	reg          [6:0]sign_type;
	
	`include "vlc_tables.v"


  	/* position in video stream */
  	reg              sequence_header_seen;    /* set when sequence header encountered, cleared when sequence end encountered  */
  	reg              picture_header_seen;     /* set when picture header encountered, cleared when sequence end encountered  */

  	/* in picture header */
  	reg         [2:0]picture_coding_type;
 	wire        [2:0]forward_f_code;
  	wire        [2:0]backward_f_code;

  	/* in slice */
  	reg              first_macroblock_of_slice;

  	/* macroblock address increment */
  	wire        [3:0]macroblock_addr_inc_length;
  	wire        [5:0]macroblock_addr_inc_value;
  	wire             macroblock_addr_inc_escape;
  	reg         [6:0]macroblock_address_increment;

  	/* macroblock type */
  	wire        [3:0]macroblock_type_length;
  	wire        [5:0]macroblock_type_value;
  	reg              macroblock_quant;
  	reg				 macroblock_motion_forward;
  	reg				 macroblock_motion_backward;
  	reg              macroblock_pattern;
 	reg				 macroblock_intra;

  	/* motion vectors */
  	reg         [3:0]motion_vector_reg;  // bitmask of motion vectors present
	reg			[1:0]motion_vector;		//current motion vector
  	reg         [3:0]r_size; // f_code_xx  - 4'd1;

	reg         [5:0]coded_block_pattern;
  	wire             dct_coefficient_escape;
	wire             non_signed_dct;
	wire             extended_dct_escape;

  	/* motion code vlc lookup */
  	wire        [3:0]motion_code_length;
  	wire        [4:0]motion_code_value;
  	wire             motion_code_sign;
	
	  	/* coded block pattern vlc lookup */
  	wire        [3:0]coded_block_pattern_length;
  	wire        [5:0]coded_block_pattern_value;
	
	reg         [3:0]dct_dc_size;

  	/* dct dc size luminance vlc lookup */
  	wire        [3:0]dct_dc_size_luminance_length;
  	wire        [4:0]dct_dc_size_luminance_value;

  	/* dct dc size chrominance vlc lookup */
  	wire        [3:0]dct_dc_size_chrominance_length;
  	wire        [4:0]dct_dc_size_chrominance_value;

  	/* dct coefficient 0 vlc lookup */
  	reg        [15:0]dct_coefficient_0_decoded;
  	reg        [15:0]dct_non_intra_first_coefficient_0_decoded;
	
	reg         [1:0]compensation_cnt;
	
	parameter [5:0]
		STATE_NEXT_START_CODE     = 6'h00, 
		STATE_START_CODE          = 6'h01, 

		STATE_SEQUENCE_HEADER     = 6'h02, 
		STATE_SEQUENCE_HEADER2    = 6'h03, 
		STATE_SEQUENCE_HEADER3    = 6'h04, 
		STATE_LD_INTRA_QUANT0     = 6'h05, 
		STATE_LD_NON_INTRA_QUANT0 = 6'h06, 

		STATE_GROUP_HEADER        = 6'h07, 
		STATE_GROUP_HEADER0       = 6'h08, 

		STATE_PICTURE_HEADER      = 6'h09, 
		STATE_PICTURE_HEADER0     = 6'h0a, 
		STATE_PICTURE_HEADER1     = 6'h0b, 
		STATE_PICTURE_HEADER2     = 6'h0c, 
		STATE_PICTURE_EXTRA_INFO  = 6'h0d, 

		STATE_SLICE               = 6'h0e, 
		STATE_SLICE_EXTRA_INFO    = 6'h0f, 

		STATE_NEXT_MACROBLOCK     = 6'h10, 
		STATE_MACROBLOCK_TYPE     = 6'h11, 
		STATE_MACROBLOCK_QUANT    = 6'h12, 
		
		STATE_NEXT_MOTION_VECTOR  = 6'h13, 
		STATE_MOTION_CODE         = 6'h14, 
		STATE_MOTION_RESIDUAL     = 6'h15, 
		
		STATE_CODED_BLOCK_PATTERN = 6'h16, 
		STATE_NEXT_BLOCK          = 6'h17, 
		STATE_DCT_DC_LUMI_SIZE    = 6'h18, 
		STATE_DCT_DC_CHROMI_SIZE  = 6'h19, 
		STATE_DCT_DC_DIFF         = 6'h1a, 
		
		STATE_DCT_NON_INTRA_FIRST = 6'h1b, 
		STATE_DCT_SUBS_B14        = 6'h1c, 
		STATE_DCT_ESCAPE_B14      = 6'h1d, 

		STATE_SEQUENCE_END        = 6'h1e, 
		STATE_ERROR               = 6'h1f,
		
		STATE_SKIP0               = 6'h20,
		STATE_SKIP_CHECK          = 6'h21,
		STATE_SKIP1               = 6'h22,
		STATE_COMPENSATION        = 6'h23;


		/* start codes */
  	parameter [7:0]
    	CODE_PICTURE_START        = 8'h00,
    	CODE_USER_DATA_START      = 8'hb2,
    	CODE_SEQUENCE_HEADER      = 8'hb3,
    	CODE_SEQUENCE_ERROR       = 8'hb4,
    	CODE_EXTENSION_START      = 8'hb5,
    	CODE_SEQUENCE_END         = 8'hb7,
    	CODE_GROUP_START          = 8'hb8;
		
		
	//next state
	always @* begin
		casez(state)
			STATE_NEXT_START_CODE           : if(getbits == 24'h000001) next = STATE_START_CODE;
                                              else                      next = STATE_NEXT_START_CODE;
			STATE_START_CODE				:
				casex(getbits[7:0])
            	    CODE_PICTURE_START      : if (sequence_header_seen)	next = STATE_PICTURE_HEADER;
                                              else                      next = STATE_NEXT_START_CODE;
					CODE_USER_DATA_START,
					CODE_SEQUENCE_ERROR,
					CODE_EXTENSION_START    : next = STATE_NEXT_START_CODE;
					CODE_SEQUENCE_HEADER    : next = STATE_SEQUENCE_HEADER;
					CODE_SEQUENCE_END       : next = STATE_SEQUENCE_END;
					CODE_GROUP_START        : next = STATE_GROUP_HEADER;
					8'h01,
					8'h02,
					8'h03,
					8'h04,
					8'h05,
					8'h06,
					8'h07,
					8'h08,
					8'h09,
					8'h0a,
					8'h0b,
					8'h0c,
					8'h0d,
					8'h0e,
					8'h0f,
					8'h1x,
					8'h2x,
					8'h3x,
					8'h4x,
					8'h5x,
					8'h6x,
					8'h7x,
					8'h8x,
					8'h9x,
					8'hax                   : if (sequence_header_seen & picture_header_seen) next = STATE_SLICE;
                                              else                                            next = STATE_NEXT_START_CODE;
					default                   next = STATE_NEXT_START_CODE;
				endcase 

            STATE_SEQUENCE_HEADER           : next = STATE_SEQUENCE_HEADER2; 

            STATE_SEQUENCE_HEADER2          : next = STATE_SEQUENCE_HEADER3; 

            STATE_SEQUENCE_HEADER3          : if (getbits[4])      next = STATE_LD_INTRA_QUANT0;
                                              else if (getbits[3]) next = STATE_LD_NON_INTRA_QUANT0;
                                              else                  next = STATE_NEXT_START_CODE;

            STATE_LD_INTRA_QUANT0           : if (cnt != 6'b111111) next = STATE_LD_INTRA_QUANT0;
                                              else if (getbits[15]) next = STATE_LD_NON_INTRA_QUANT0;
                                              else                  next = STATE_NEXT_START_CODE;

            STATE_LD_NON_INTRA_QUANT0       : if (cnt != 6'b111111) next = STATE_LD_NON_INTRA_QUANT0;
                                              else                  next = STATE_NEXT_START_CODE;


            STATE_GROUP_HEADER              : next = STATE_GROUP_HEADER0;
			
            STATE_GROUP_HEADER0             : next = STATE_NEXT_START_CODE;

            STATE_PICTURE_HEADER            : next = STATE_PICTURE_HEADER0;
			
            STATE_PICTURE_HEADER0           : if ((picture_coding_type == 3'h2) || (picture_coding_type == 3'h3)) next = STATE_PICTURE_HEADER1;
                                              else                                                                next = STATE_PICTURE_EXTRA_INFO;
													
            STATE_PICTURE_HEADER1           : if (picture_coding_type == 3'h3) next = STATE_PICTURE_HEADER2;
                                              else                             next = STATE_PICTURE_EXTRA_INFO;
													
            STATE_PICTURE_HEADER2           : next = STATE_PICTURE_EXTRA_INFO;
			
			STATE_PICTURE_EXTRA_INFO        : if (getbits[23]) next = STATE_PICTURE_EXTRA_INFO;
                                              else             next = STATE_NEXT_START_CODE;


			STATE_SLICE                     : if (getbits[18]) next = STATE_SLICE_EXTRA_INFO; // getbits[18] is slice_extension_flag
                                              else             next = STATE_NEXT_MACROBLOCK;
													
			STATE_SLICE_EXTRA_INFO          : if (getbits[15]) next = STATE_SLICE_EXTRA_INFO; // getbits[15] indicates another extra_information_slice byte follows
                                              else             next = STATE_NEXT_MACROBLOCK;


			STATE_NEXT_MACROBLOCK           : if(picture_coding_type == 3'd1 && getbits == 24'hE52948) next = STATE_SKIP0;
											  else if (macroblock_addr_inc_escape)                     next = STATE_NEXT_MACROBLOCK; // macroblock address escape
                                              else if (macroblock_addr_inc_value == 6'd0)              next = STATE_ERROR;
                                              else                                                     next = STATE_MACROBLOCK_TYPE;
											  
			STATE_SKIP0						: next = STATE_SKIP_CHECK;
											  
			STATE_SKIP_CHECK				: if(getbits[23:16] == 8'h22) next = STATE_SKIP1;
											  else                        next = STATE_COMPENSATION;
											  
			STATE_SKIP1						: next = STATE_NEXT_BLOCK;
			
			STATE_COMPENSATION 				: if(compensation_cnt == 2'd0) next = STATE_NEXT_BLOCK;
											  else                         next = STATE_COMPENSATION;
													
			STATE_MACROBLOCK_TYPE           : next = STATE_MACROBLOCK_QUANT;
			
			STATE_MACROBLOCK_QUANT          : if(macroblock_motion_forward || macroblock_motion_backward) next = STATE_NEXT_MOTION_VECTOR;
											  else if(macroblock_pattern)                                 next = STATE_CODED_BLOCK_PATTERN;
											  else                                                        next = STATE_NEXT_BLOCK;
			
			STATE_NEXT_MOTION_VECTOR        : if(motion_vector_reg== 4'h0 && macroblock_pattern) next = STATE_CODED_BLOCK_PATTERN;
											  else if(motion_vector_reg== 4'h0)                  next = STATE_NEXT_BLOCK;
                                              else if (motion_vector_reg[3])                     next = STATE_MOTION_CODE;
                                              else                                               next = STATE_NEXT_MOTION_VECTOR;
													
			STATE_MOTION_CODE               : if( (r_size != 0) && (getbits[23] != 1'b1) ) next = STATE_MOTION_RESIDUAL;
                                              else                                         next = STATE_NEXT_MOTION_VECTOR;
													
			STATE_MOTION_RESIDUAL           : next = STATE_NEXT_MOTION_VECTOR;
			
			STATE_CODED_BLOCK_PATTERN       : if (macroblock_pattern && coded_block_pattern_length == 4'b0) next = STATE_ERROR; // Invalid coded_block_pattern code
                                              else                                                          next = STATE_NEXT_BLOCK;
													
													
			STATE_NEXT_BLOCK                : if (coded_block_pattern[5] && macroblock_intra &&    //
                                                 ( sign_type[2] || sign_type[1]) )                 next = STATE_DCT_DC_CHROMI_SIZE;		// chrominance block
                                              else if (coded_block_pattern[5] && macroblock_intra) next = STATE_DCT_DC_LUMI_SIZE; 		// luminance block
                                              else if (coded_block_pattern[5])                     next = STATE_DCT_NON_INTRA_FIRST;	// 
                                              else if (coded_block_pattern != 6'b0)                next = STATE_NEXT_BLOCK;				// shift block_pattern_code and block_lumi_code one bit, find next block
                                              else if ((getbits[23:1] == 23'b0))                   next = STATE_NEXT_START_CODE; 		// end of slice, go to next start code (par. 6.2.4). In case of error, synchronize at next start code.
                                              else                                                 next = STATE_NEXT_MACROBLOCK; 		// end of macroblock, but not end of slice: go to next macroblock. 

			STATE_DCT_DC_LUMI_SIZE          : if (dct_dc_size_luminance_length == 4'b0)    next = STATE_ERROR;
											  else if(dct_dc_size_luminance_value == 5'd0) next = STATE_DCT_SUBS_B14;
                                              else                                         next = STATE_DCT_DC_DIFF; // table B-12 lookup of first luminance dct coefficient

			STATE_DCT_DC_CHROMI_SIZE        : if (dct_dc_size_chrominance_length == 4'b0)    next = STATE_ERROR;
											  else if(dct_dc_size_chrominance_value == 5'd0) next = STATE_DCT_SUBS_B14;
                                              else                                           next = STATE_DCT_DC_DIFF; // table B-13 lookup of first chrominance dct coefficient

			STATE_DCT_DC_DIFF               : next = STATE_DCT_SUBS_B14;
			
			STATE_DCT_NON_INTRA_FIRST       : if (dct_coefficient_escape)                                        next = STATE_DCT_ESCAPE_B14; // table B-14 escape
                                              else if (dct_non_intra_first_coefficient_0_decoded[15:11] == 5'b0) next = STATE_ERROR; // unknown code
                                              else                                                               next = STATE_DCT_SUBS_B14;
													
			STATE_DCT_SUBS_B14              : if (getbits[23:22] == 2'b10)                       next = STATE_NEXT_BLOCK; // end of this block, go to next block
                                              else if (dct_coefficient_escape)                   next = STATE_DCT_ESCAPE_B14; // Escape
                                              else if (dct_coefficient_0_decoded[15:11] == 5'b0) next = STATE_ERROR; // unknown code
                                              else                                               next = STATE_DCT_SUBS_B14;
													
			STATE_DCT_ESCAPE_B14            : next = STATE_DCT_SUBS_B14;
			
			STATE_SEQUENCE_END              : next = STATE_NEXT_START_CODE;
			STATE_ERROR                     : next = STATE_NEXT_START_CODE;
			default                           next = STATE_ERROR;
		endcase
	end
	
	//advance
	always @* begin
		casez(state)
			STATE_NEXT_START_CODE           : advance = 5'd0;	//align = 1
			STATE_START_CODE                : advance = 5'd24;

			STATE_SEQUENCE_HEADER           : advance = 5'd24;
			STATE_SEQUENCE_HEADER2          : advance = 5'd19;
			STATE_SEQUENCE_HEADER3          : advance = 5'd20;
			STATE_LD_INTRA_QUANT0           : advance = 5'd8;
			STATE_LD_NON_INTRA_QUANT0       : advance = 5'd8;

			STATE_GROUP_HEADER              : advance = 5'd19;
			STATE_GROUP_HEADER0             : advance = 5'd8;

			STATE_PICTURE_HEADER            : advance = 5'd13;
			STATE_PICTURE_HEADER0           : advance = 5'd16;
			STATE_PICTURE_HEADER1           : advance = 5'd4;
			STATE_PICTURE_HEADER2           : advance = 5'd4;
			STATE_PICTURE_EXTRA_INFO        : advance = getbits[23] ? 5'd9 : 5'd1;

			STATE_SLICE                     : advance = 5'd6;
			STATE_SLICE_EXTRA_INFO          : advance = 5'd9;

			STATE_NEXT_MACROBLOCK           : advance = macroblock_addr_inc_length;
			STATE_MACROBLOCK_TYPE           : advance = macroblock_type_length;
			STATE_MACROBLOCK_QUANT          : advance = macroblock_quant ? 5'd5 : 5'd0;
			STATE_NEXT_MOTION_VECTOR        : advance = 5'd0;
			STATE_MOTION_CODE               : advance = motion_code_length;
			STATE_MOTION_RESIDUAL           : advance = r_size;
			STATE_CODED_BLOCK_PATTERN       : advance = coded_block_pattern_length;
			STATE_NEXT_BLOCK                : advance = 5'd0;
			STATE_DCT_DC_LUMI_SIZE          : advance = dct_dc_size_luminance_length;
			STATE_DCT_DC_CHROMI_SIZE        : advance = dct_dc_size_chrominance_length;
			STATE_DCT_DC_DIFF               : advance = dct_dc_size;
			STATE_DCT_NON_INTRA_FIRST       : advance = dct_coefficient_escape ? 5'd12 : dct_non_intra_first_coefficient_0_decoded[15:11];
			STATE_DCT_SUBS_B14              : advance = dct_coefficient_escape ? 5'd12 : dct_coefficient_0_decoded[15:11];
        	STATE_DCT_ESCAPE_B14            : advance = extended_dct_escape ? 5'd16 : 5'd8;
			STATE_SKIP0						: advance = 5'd21;
			STATE_SKIP1                     : advance = 5'd8;
			STATE_SKIP_CHECK                : advance = 5'd0;
			STATE_COMPENSATION 				: advance = 5'd0;
			STATE_SEQUENCE_END              : advance = 5'd0;
			STATE_ERROR                     : advance = 5'd0;
			default                           advance = 5'd0;
		endcase
	end
	
	//align
	assign align = (state == STATE_NEXT_START_CODE);
	
	//next_sign_en
	assign next_sign_en =	(state == STATE_MOTION_CODE && getbits[23] != 1'b1) ||
									(state == STATE_DCT_DC_DIFF && dct_dc_size != 0) ||
									(( state == STATE_DCT_SUBS_B14 || state == STATE_DCT_NON_INTRA_FIRST) && ~non_signed_dct) ||
									(state == STATE_DCT_ESCAPE_B14);
	
	//next_sign_loc
	always @* begin
		casez(state)
			STATE_MOTION_CODE,
			STATE_DCT_SUBS_B14,
			STATE_DCT_NON_INTRA_FIRST :	next_sign_loc = 1'b1;
			default                     next_sign_loc = 1'b0;
		endcase
	end
	
	//next_extend_en
	assign next_extend_en = (	state == STATE_DCT_ESCAPE_B14 && extended_dct_escape && getbits[14:8] != 7'b000_0000);
	
	//sign_offset
	assign sign_offset = (next_sign_loc ? 5'd24 - advance : 5'd23);

	
	//state
	always @(posedge clk)
    	if (~rst) state <= STATE_NEXT_START_CODE;
    	else if (module_en) state <= next;
    	else state <= state;
		
	
	//align_reg
  	always @(posedge clk)
    	if (~rst)          align_reg <= 1'b0;
    	else if(module_en) align_reg <= align;
    	else if(clk_en)    align_reg <= 1'b0;
		else               align_reg <= align_reg;

	//advance_reg
  	always @(posedge clk)
    	if (~rst)          advance_reg <= 1'b0;
    	else if(module_en) advance_reg <= advance;
    	else if(clk_en)    advance_reg <= 1'b0;
		else               advance_reg <= advance_reg;
		
	/*
   * wait_state is asserted if align or advance will be non-zero during the next clock cycle, 
   * and getbits will need to do some work. 
   * Unregistered output; the registering happens in getbits.
   */
	//assign wait_state = ((align != 1'b0) || (advance != 5'b0));
	
	
	//sign_en
	always @(posedge clk)
		if(~rst)           sign_en <= 1'b0;
		else if(module_en) sign_en <= next_sign_en;
		else if(clk_en)    sign_en <= 1'b0;
		else               sign_en <= sign_en;
	
	//sign_bit
	always @(posedge clk)
		if(~rst)                            sign_bit <= 1'b0;
		else if (module_en && next_sign_en) sign_bit <= getbits[sign_offset];
		else                                sign_bit <= sign_bit;
	
		
	//sign_loc
	always @(posedge clk)
		if(~rst) 							sign_loc <= 1'b0;
		else if(module_en && next_sign_en) 	sign_loc <= next_sign_loc;
		else								sign_loc <= sign_loc;
		
	//extend_en
	always @(posedge clk)
		if(~rst) 		   extend_en <= 1'b0;
		else if(module_en) extend_en <= next_extend_en;
		else if(clk_en)	   extend_en <= 1'b0;
		else               extend_en <= extend_en;
		
		
	//sign_type
	always @(posedge clk)
		if(~rst) sign_type <= 7'h0;
		else if (module_en && state == STATE_SKIP0)              sign_type <= 7'b0_000100;
		else if (module_en && state == STATE_MACROBLOCK_QUANT)	 sign_type <= 7'b1_000000;
		else if (module_en && state == STATE_NEXT_BLOCK )        sign_type <= { sign_type[0], sign_type[6:1]};
		else                                                     sign_type <= sign_type;
	
	always @(posedge clk)
		if(~rst) 		   group_change <= 1'b0;
		else if(module_en) group_change <= state == STATE_NEXT_BLOCK || state == STATE_COMPENSATION;
		else if(clk_en)	   group_change <= 1'b0;
		else               group_change <= group_change;
		
	//macroblock_end
	always@(posedge clk)
		if(~rst)           macroblock_end <= 1'b0;
		else if(module_en) macroblock_end <= state == STATE_NEXT_BLOCK && (next == STATE_NEXT_MACROBLOCK || next == STATE_NEXT_START_CODE);
		else if(clk_en)    macroblock_end <= 1'b0;
		else               macroblock_end <= macroblock_end;
	
	//slice_end 
	always@(posedge clk)
		if(~rst)           slice_end <= 1'b0;
		else if(module_en) slice_end <= state == STATE_NEXT_BLOCK && next == STATE_NEXT_START_CODE;
		else if(clk_en)    slice_end <= 1'b0;
		else               slice_end <= slice_end;
		

	/* position in video stream */
  	always @(posedge clk)
    	if (~rst) sequence_header_seen <= 1'b0;
    	else if (module_en && (state == STATE_SEQUENCE_HEADER)) sequence_header_seen <= 1'b1;
    	else if (module_en && (state == STATE_SEQUENCE_END)) sequence_header_seen <= 1'b0;
    	else sequence_header_seen <= sequence_header_seen;

  	always @(posedge clk)
   	if (~rst) picture_header_seen <= 1'b0;
    	else if (module_en && (state == STATE_PICTURE_HEADER)) picture_header_seen <= 1'b1;
    	else if (module_en && (state == STATE_SEQUENCE_END)) picture_header_seen <= 1'b0;
    	else picture_header_seen <= picture_header_seen;
	
	
	/* quantisizer matrix counter*/
	always @(posedge clk)
    	if (~rst) cnt <= 6'b0;
    	else if (module_en && (state == STATE_SEQUENCE_HEADER3) ) cnt <= 6'h0;
    	else if (module_en && 
					( (state == STATE_LD_INTRA_QUANT0) || (state == STATE_LD_NON_INTRA_QUANT0) ) ) cnt <= cnt + 1;
		else cnt <= cnt;


	//picture
	always @(posedge clk)
		if(~rst)                                            picture_coding_type <= 3'b0;
		else if(module_en && state == STATE_PICTURE_HEADER) picture_coding_type <= getbits[13:11];
		else                                                picture_coding_type <= picture_coding_type;
	
  	loadreg #( .offset(1), .width(3), .fsm_state(STATE_PICTURE_HEADER1)) loadreg_forward_f_code(.fsm_reg(forward_f_code), .clk(clk), .clk_en(module_en), .rst(rst), .state(state), .getbits(getbits));
	loadreg #( .offset(1), .width(3), .fsm_state(STATE_PICTURE_HEADER2)) loadreg_backward_f_code(.fsm_reg(backward_f_code), .clk(clk), .clk_en(module_en), .rst(rst), .state(state), .getbits(getbits));


	/* par. 6.2.4: slice */
	/* macroblock address increment vlc lookup */
    assign {macroblock_addr_inc_length, macroblock_addr_inc_value, macroblock_addr_inc_escape} = macroblock_address_increment_dec(getbits[23:13]);
	
	/* macroblock type vlc lookup */
  	assign {macroblock_type_length, macroblock_type_value} = macroblock_type_dec(getbits[23:18], picture_coding_type);

	/* coded block pattern vlc lookup */
  	assign {coded_block_pattern_length, coded_block_pattern_value} = coded_block_pattern_dec(getbits[23:15]);

  	/* motion code vlc lookup */
  	assign {motion_code_length, motion_code_value, motion_code_sign} = motion_code_dec(getbits[23:13]);

    /* dct dc size luminance vlc lookup */
    assign {dct_dc_size_luminance_length, dct_dc_size_luminance_value} = dct_dc_size_luminance_dec(getbits[23:15]);

	/* dct dc size chrominance vlc lookup */
  	assign {dct_dc_size_chrominance_length, dct_dc_size_chrominance_value} = dct_dc_size_chrominance_dec(getbits[23:14]);
	
	assign dct_coefficient_escape = (getbits[23:18] == 6'b000001); // one if dct coefficient escape in table B-14 or B-15
	
	assign non_signed_dct = dct_coefficient_escape || (getbits[23:22] == 2'b10 && state == STATE_DCT_SUBS_B14);
	
	assign extended_dct_escape		= (getbits[22:16] == 7'b0000000);

  	/* dct coefficient 0 vlc lookup */
  	always @(getbits)
    	dct_coefficient_0_decoded = dct_coefficient_0_dec(getbits[23:8]);

  	/* dct first coefficient 0 vlc lookup */
  	/* see note 2 and 3 of table B-14: first coefficient handled differently. */
  	/* Code 2'b10 = 1, Code 2'b11 = -1 */
  	always @(getbits, dct_coefficient_0_decoded)
    	dct_non_intra_first_coefficient_0_decoded = getbits[23] ? {5'd2, 5'd0, 6'd1} : dct_coefficient_0_decoded;

	 
	/* macroblock type */
  	always @(posedge clk)
    	if (~rst)                                               macroblock_quant <= 1'b0;
		else if (module_en && state == STATE_SKIP0)             macroblock_quant <= 1'b0;
    	else if (module_en && (state == STATE_MACROBLOCK_TYPE)) macroblock_quant <= macroblock_type_value[5];
    	else                                                    macroblock_quant <= macroblock_quant;

  	always @(posedge clk)
    	if (~rst)                                               macroblock_motion_forward <= 1'b0;
		else if (module_en && state == STATE_SKIP0)             macroblock_motion_forward <= 1'b0;
    	else if (module_en && (state == STATE_MACROBLOCK_TYPE)) macroblock_motion_forward <= macroblock_type_value[4];
    	else                                                    macroblock_motion_forward <= macroblock_motion_forward;

  	always @(posedge clk)
    	if (~rst)                                               macroblock_motion_backward <= 1'b0;
		else if (module_en && state == STATE_SKIP0)             macroblock_motion_backward <= 1'b0;           
		else if (module_en && (state == STATE_MACROBLOCK_TYPE)) macroblock_motion_backward <= macroblock_type_value[3];
		else                                                    macroblock_motion_backward <= macroblock_motion_backward;

  	always @(posedge clk)
    	if (~rst) macroblock_pattern <= 1'b0;
		else if (module_en && state == STATE_SKIP0)             macroblock_pattern <= 1'b0;
    	else if (module_en && (state == STATE_MACROBLOCK_TYPE)) macroblock_pattern <= macroblock_type_value[2];
    	else macroblock_pattern <= macroblock_pattern;

  	always @(posedge clk)
    	if (~rst) macroblock_intra <= 1'b0;
		else if (module_en && state == STATE_SKIP0)             macroblock_intra <= 1'b1;
    	else if (module_en && (state == STATE_MACROBLOCK_TYPE)) macroblock_intra <= macroblock_type_value[1];
    	else macroblock_intra <= macroblock_intra;


	// motion_vector_reg
	always @(posedge clk)
    	if (~rst) motion_vector_reg <= 4'b0;
    	else if (module_en && (state == STATE_MACROBLOCK_QUANT)) begin
			case( {macroblock_motion_forward, macroblock_motion_backward} )
				2'b00		:	motion_vector_reg <= 4'b0000; 	//no motion vector
				2'b10		:	motion_vector_reg <= 4'b1100;	//forward
				2'b01		:	motion_vector_reg <= 4'b0011;	//backward
				2'b11		:	motion_vector_reg <= 4'b1111;	//bidirectional
			endcase
		end
    	else if (module_en && (state == STATE_NEXT_MOTION_VECTOR)) motion_vector_reg <= motion_vector_reg << 1;
    	else motion_vector_reg <= motion_vector_reg;
		
	/* motion code variables, par. 6.2.5, 6.2.5.2, 6.2.5.2.1 */
   /*
   * motion_vector cycles through the different motion vectors
   * The msb of  motion_vector_reg is one if the motion vector actually occurs in the bitstream.
   */
  always @(posedge clk)
    if (~rst) motion_vector <= 2'b0;
    else if (module_en && (state == STATE_MACROBLOCK_QUANT)) motion_vector <= 2'b0; 
    else if (module_en && (state == STATE_NEXT_MOTION_VECTOR))motion_vector <= motion_vector + 1;
    else motion_vector <= motion_vector;

		
	// residual size = f_code - 1;
	always @(posedge clk)
		if (~rst) r_size <= 4'd0;
		else if (module_en && (state == STATE_NEXT_MOTION_VECTOR) && (motion_vector[1] == 1'b0) ) r_size <= forward_f_code - 4'd1;
		else if (module_en && (state == STATE_NEXT_MOTION_VECTOR) && (motion_vector[1] == 1'b1) ) r_size <= backward_f_code - 4'd1;
		else r_size <= r_size;
		

	/* coded block pattern */
  	always @(posedge clk) // // par. 6.3.17.4
    	if (~rst) coded_block_pattern <= 6'b0;
		else if (module_en && state == STATE_SKIP0)                                       coded_block_pattern <= 6'b110000;
		else if (module_en && state == STATE_SKIP1)                                       coded_block_pattern <= 6'b000000;
		else if (module_en && (state == STATE_MACROBLOCK_QUANT) && macroblock_intra)      coded_block_pattern <= 6'b111111;
		else if (module_en && (state == STATE_MACROBLOCK_QUANT) )					      coded_block_pattern <= 6'b000000;
    	else if (module_en && (state == STATE_CODED_BLOCK_PATTERN) && macroblock_pattern) coded_block_pattern <= coded_block_pattern_value;
		else if (module_en && (state == STATE_NEXT_BLOCK)) 								  coded_block_pattern <= coded_block_pattern << 1;
    	else coded_block_pattern <= coded_block_pattern;
		
	//dct_dc_size
	always @(posedge clk)
		if (~rst) dct_dc_size <= 4'b0;
		else if (module_en && (state == STATE_DCT_DC_LUMI_SIZE)) dct_dc_size <= dct_dc_size_luminance_value;     // table B-12 lookup
		else if (module_en && (state == STATE_DCT_DC_CHROMI_SIZE)) dct_dc_size <= dct_dc_size_chrominance_value; // table B-13 lookup
		else dct_dc_size <= dct_dc_size;
		
	assign module_en = clk_en && vld_en;
	
	always @(posedge clk)
		if(~rst) compensation_cnt <= 2'd3;
		else if(module_en && state == STATE_COMPENSATION) compensation_cnt <= compensation_cnt - 1;
		else if(module_en)                                compensation_cnt <= compensation_cnt;
		else                                              compensation_cnt <= compensation_cnt;

//debug

`ifdef DEBUG
    always @(posedge clk)
        if (module_en)
            case (state)
                STATE_INIT:                       #0 $display("%m\tSTATE_INIT");
                STATE_NEXT_START_CODE:            #0 $display("%m\tSTATE_NEXT_START_CODE");
                STATE_START_CODE:                 #0 $display("%m\tSTATE_START_CODE");
                STATE_PICTURE_HEADER:             #0 $display("%m\tSTATE_PICTURE_HEADER");
                STATE_PICTURE_HEADER0:            #0 $display("%m\tSTATE_PICTURE_HEADER0");
                STATE_PICTURE_HEADER1:            #0 $display("%m\tSTATE_PICTURE_HEADER1");
                STATE_PICTURE_HEADER2:            #0 $display("%m\tSTATE_PICTURE_HEADER2");
                STATE_PICTURE_EXTRA_INFO:         #0 $display("%m\tSTATE_PICTURE_EXTRA_INFORMATION");
                STATE_SEQUENCE_HEADER:            #0 $display("%m\tSTATE_SEQUENCE_HEADER");
                STATE_SEQUENCE_HEADER2:           #0 $display("%m\tSTATE_SEQUENCE_HEADER2");
                STATE_SEQUENCE_HEADER3:           #0 $display("%m\tSTATE_SEQUENCE_HEADER3");
                STATE_GROUP_HEADER:               #0 $display("%m\tSTATE_GROUP_HEADER");
                STATE_GROUP_HEADER0:              #0 $display("%m\tSTATE_GROUP_HEADER0");
                STATE_LD_INTRA_QUANT0:            #0 $display("%m\tSTATE_LD_INTRA_QUANT0");
                STATE_LD_NON_INTRA_QUANT0:        #0 $display("%m\tSTATE_LD_NON_INTRA_QUANT0");
                STATE_SLICE:                      #0 $display("%m\tSTATE_SLICE");
                STATE_SLICE_EXTRA_INFO:           #0 $display("%m\tSTATE_SLICE_EXTRA_INFORMATION");
                STATE_NEXT_MACROBLOCK:            #0 $display("%m\tSTATE_NEXT_MACROBLOCK");
                STATE_MACROBLOCK_TYPE:            #0 $display("%m\tSTATE_MACROBLOCK_TYPE");
                STATE_MACROBLOCK_QUANT:           #0 $display("%m\tSTATE_MACROBLOCK_QUANT");
                STATE_NEXT_MOTION_VECTOR:         #0 $display("%m\tSTATE_NEXT_MOTION_VECTOR");
                STATE_MOTION_CODE:                #0 $display("%m\tSTATE_MOTION_CODE");
                STATE_MOTION_RESIDUAL:            #0 $display("%m\tSTATE_MOTION_RESIDUAL");
                STATE_CODED_BLOCK_PATTERN:        #0 $display("%m\tSTATE_CODED_BLOCK_PATTERN");
                STATE_NEXT_BLOCK:                 #0 $display("%m\tSTATE_NEXT_BLOCK");
                STATE_DCT_DC_LUMI_SIZE:           #0 $display("%m\tSTATE_DCT_DC_LUMI_SIZE");
                STATE_DCT_DC_CHROMI_SIZE:         #0 $display("%m\tSTATE_DCT_DC_CHROMI_SIZE");
                STATE_DCT_DC_DIFF:                #0 $display("%m\tSTATE_DCT_DC_DIFF");
                STATE_DCT_SUBS_B14:               #0 $display("%m\tSTATE_DCT_SUBS_B14");
                STATE_DCT_ESCAPE_B14:             #0 $display("%m\tSTATE_DCT_ESCAPE_B14");
                STATE_DCT_NON_INTRA_FIRST:        #0 $display("%m\tSTATE_DCT_NON_INTRA_FIRST");
                STATE_SEQUENCE_END:               #0 $display("%m\tSTATE_SEQUENCE_END");
                STATE_ERROR:                      #0 $display("%m\tSTATE_ERROR");
                default                           begin
                                                      #0 $display("%m\tUnknown state");
                                                      $finish;
                                                  end
            endcase
        else begin
            #0 $display("%m\tnot module_en");
        end

   always @(posedge clk)
     if (module_en)
       case (state)
         STATE_NEXT_MACROBLOCK:
           begin
             $strobe ("%m\tmacroblock_addr_inc_value: %d", macroblock_addr_inc_value);
           end

         STATE_MACROBLOCK_TYPE:
           begin
             $strobe ("%m\tmacroblock_quant: %d", macroblock_quant);
             $strobe ("%m\tmacroblock_motion_forward: %d", macroblock_motion_forward);
             $strobe ("%m\tmacroblock_motion_backward: %d", macroblock_motion_backward);
             $strobe ("%m\tmacroblock_pattern: %d", macroblock_pattern);
             $strobe ("%m\tmacroblock_intra: %d", macroblock_intra);
           end

         STATE_MACROBLOCK_QUANT:
           begin
             $strobe ("%m\tmotion_vector_reg: %4b", motion_vector_reg);
           end

         STATE_NEXT_MOTION_VECTOR:    
           begin
             $strobe ("%m\tmotion_vector_reg: %4b", motion_vector_reg);
           end

         STATE_MOTION_CODE:
           begin
             $strobe ("%m\tr_size: %d", r_size);
				 $strobe ("%m\tmotion code: %d", motion_code_value);
				 if(getbits[23] != 1'b1)begin 
					$strobe ("%m\tsign type : %b", sign_type);
					$strobe ("%m\tdct sign : %b", sign_bit);
				 end
				 else $strobe ("%m\tno motion sign");
           end

         STATE_CODED_BLOCK_PATTERN:
           begin
			    $strobe ("%m\tmacroblock_intra: b%b", macroblock_intra);
             $strobe ("%m\tmacroblock_pattern: b%b", macroblock_pattern);
             $strobe ("%m\tcoded_block_pattern:  b%b", coded_block_pattern);
           end

         STATE_NEXT_BLOCK:
           begin
             $strobe ("%m\tcoded_block_pattern:  b%b", coded_block_pattern);
           end

         STATE_DCT_DC_LUMI_SIZE:
           begin
             $strobe ("%m\tdct_dc_size_luminance_length: %d", dct_dc_size_luminance_length);
             $strobe ("%m\tdct_dc_size_luminance_value: %d", dct_dc_size_luminance_value);
           end

         STATE_DCT_DC_CHROMI_SIZE:
           begin
             $strobe ("%m\tdct_dc_size_chrominance_length: %d", dct_dc_size_chrominance_length);
             $strobe ("%m\tdct_dc_size_chrominance_value: %d", dct_dc_size_chrominance_value);
           end

         STATE_DCT_DC_DIFF:
           begin
             if (dct_dc_size != 0)
               begin
					  $strobe ("%m\tsign type : %b", sign_type);
					  $strobe ("%m\tdct sign : %b", sign_bit);
               end
				 else begin
					$strobe ("%m\tdct_dc: 0");
				 end
           end

         STATE_DCT_SUBS_B14,
         STATE_DCT_NON_INTRA_FIRST,
         STATE_DCT_ESCAPE_B14:
			begin
            	if(next_sign_en)begin
             		$strobe ("%m\tsign type : %b", sign_type);
				 	$strobe ("%m\tdct sign : %b", sign_bit);
           		end
			end

         STATE_ERROR:
           begin
             $strobe ("%m\tError");
           end

       endcase


   /* fifo status */
   always @(posedge clk)
     if (module_en)
       begin
         #0 $display("%m\tgetbits: %h (%b)", getbits, getbits);
       end

   always @(posedge clk)
     if (module_en)
       begin
         $strobe("%m\talign: %d advance_reg %d", align_reg, advance_reg);
       end
`endif

endmodule

/*
   Extracts a register from the bitstream.
   when reset* is asserted, clear register 'fsm_reg'
   else, when in state 'fsm_state',
   clock 'width' bits at offset 'offset' in the video stream into the register 'fsm_reg'.

 */

module loadreg #(parameter offset=0, width=8, fsm_state = 6'h1f) (
   input                  clk,
   input                  clk_en,
   input                  rst,
   input             [5:0]state,
   input            [23:0]getbits,
   output reg  [width-1:0]fsm_reg
   );
  always @(posedge clk)
    begin
      if (~rst) fsm_reg <= {32{1'b0}}; // gets truncated
      else if (clk_en && (state == fsm_state))
        begin
          fsm_reg <= getbits[23-offset -: width];
          `ifdef DEBUG
            $strobe ("%m\t%0d'd%0d (%0d'h%0h, %0d'b%0b)", width, fsm_reg, width, fsm_reg, width, fsm_reg);
          `endif
        end
      else fsm_reg <= fsm_reg;
    end
endmodule