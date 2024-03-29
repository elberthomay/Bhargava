//`undef DES
`define DES 1
`undef DEBUG
//`define DEBUG 1
module bhargava(
	
	
	input clk_en,
	
	input rst_n_200,
	input rst_n_300,
	
	input [7:0]  mpeg_in,
	input        mpeg_wr,
	output       mpeg_prog_full, 
	output       mpeg_full,
	input        stream_end,

	
	output [7:0] mpeg_out,
	input        mpeg_rd,
	output       mpeg_empty,
	
	`ifdef DES
	input [63:0] key_in, 
	input        mode_in,  
	input        key_en, 
	`endif
	
	`ifdef DEBUG
	input        clk,
	input        clk2x,
	
	output reg [31:0] vid_cnt, misc_in_cnt, vbuf_out_cnt, vlc_cnt_bit, sign_cnt_cnt, 
			   sign_switch_cnt, replacer_sign_cnt,
	output reg [31:0] vlc_sign_cnt, collator_sign_cnt, mb_ser_sign_cnt, dese64_sign_cnt, 
		       post_des_sign_cnt, unscrambler_sign_cnt, post_unscr_ser_sign_cnt,
	output [28:0] vlc_cnt_byte, ex_cnt_cnt_byte, sign_cnt_cnt_byte, sign_switch_cnt_byte,
	output [2:0] vlc_cnt_rem, ex_cnt_cnt_rem, sign_cnt_cnt_rem, sign_switch_cnt_rem,
	
	output vlc_sign_bit,
	output mb_ser_sign_bit,
	output post_des_ser_sign_bit,
	output post_unscr_ser_sign_bit
	
	`else
	input clk_200,
	input clk_300
	`endif
	
);

	`ifdef DEBUG
	//wire clk
	wire clk_200;
	wire clk_300;
	`endif
	
	wire rst_200;
	wire rst_300;
	
	wire [7:0]   mpeg_fifo_dout;
	wire         mpeg_fifo_empty;
	
	wire [7:0]   splitter_stream_out;
	wire         splitter_mpeg_rd;
	wire         splitter_vid_wr;
	wire         splitter_misc_wr;
	wire         splitter_stream_end;
	
	wire [7:0]   vid_fifo_dout;
	wire         vid_fifo_afull;
	wire         vid_fifo_empty;
	
	wire [7:0]   misc_fifo_dout;
	wire         misc_fifo_afull;
	wire         misc_fifo_empty;
	
	wire [7:0]   extender_out;
	wire         extender_wr_out;

	wire         vbuf_fifo_afull;
	wire [63:0]  vbuf_fifo_dout;
	wire         vbuf_fifo_empty;
	
	wire [23:0]  getbits_out;
	wire         getbits_vld_en;
	wire         getbits_vbuf_rd;
	
	wire [4:0]   video_advance;
	wire [4:0]   video_advance_reg;
	wire         video_align;
	wire         video_align_reg;
	wire         video_extend_en;
	wire         video_sign_en;
	wire         video_sign_loc;
	wire         video_sign_bit;
	wire         video_group_change;
	wire         video_macroblock_end;
	wire         video_slice_end;
	
	wire [90:0]  collator_mb_conf;
	wire [2:0]   collator_first_group;
	wire         collator_has_one_group;
	wire [63:0]  collator_scrambled_plaintext; 
	wire [383:0] collator_original_position;
	wire [6:0]   collator_scrambled_count;
	wire         collator_no_sign;
	wire         collator_mb_wr;
	wire         collator_mb_conf_wr;
	
    wire [456:0] mb_fifo_dout;
	wire         mb_fifo_afull;
    wire         mb_fifo_empty;
	
	wire [94:0]  mb_conf_fifo_dout;
	wire         mb_conf_fifo_afull;
	wire         mb_conf_fifo_empty;
	
	wire         mb_ser_mb_rd;
	wire         mb_ser_sign_out;
	wire [6:0]   mb_ser_bitpos_out;
    wire         mb_ser_out_wr;
	wire         mb_ser_slice_end;
	
	wire [6:0]   bitpos_fifo_dout;
    wire         bitpos_fifo_afull;
	wire         bitpos_fifo_empty;
	
	wire [63:0]  dese64_sign_out;
	wire [5:0]   dese64_size_out;
	wire         dese64_des_wr;
	wire         dese64_last_wr;
	
	wire [63:0]  des_out;
	wire         des_busy;
	wire         des_wr;
	
	wire         post_des_ser_sign_out;
	wire         post_des_ser_sign_en;
	wire         post_des_ser_last_ack;
	
	wire [63:0]  unscrambler_out;
	wire [6:0]   unscrambler_size;
	wire         unscrambler_wr;
	wire         unscrambler_bitpos_rd;
	
	wire [70:0]  unscrambled_fifo_dout;
	wire         unscrambled_fifo_empty;
	
	wire         post_unscr_ser_bit_out;
	wire         post_unscr_ser_bit_wr;
	wire         post_unscr_ser_unscrambled_fifo_rd;
	
	wire         bit_fifo_dout;
	wire         bit_fifo_empty;
	wire         bit_fifo_prog_full;
	
    wire         counter_sign_flag_out;
    wire         counter_extend_flag_out;
	wire [6:0]   counter_cnt_out;
	wire         counter_cnt_wr;
	
	wire [8:0]   sign_counter_fifo_dout;
	wire         sign_counter_fifo_afull;
	wire         sign_counter_fifo_empty;
	
    wire         switcher_sign_flag_out;
    wire         switcher_extend_flag_out;
	wire [6:0]   switcher_count_out;
	wire         switcher_count_out_wr;
	wire         switcher_mb_conf_rd;
	wire         switcher_count_rd;
	
	
	wire [8:0]   count_out_fifo_dout; 
	wire         count_out_fifo_afull;
	wire         count_out_fifo_empty;
	
	wire [7:0]   replacer_sign_data_out;
	wire         replacer_sign_last_sign_out;
	wire         replacer_sign_data_wr;
	wire         replacer_sign_vid_rd;
	wire         replacer_sign_cnt_rd;
	wire         replacer_sign_sign_rd;
	
	wire [8:0]   replacer_fifo_dout;
	wire         replacer_fifo_afull;
	wire         replacer_fifo_empty;
	
	wire [7:0]   processed_vid_fifo_dout;
	wire         processed_vid_fifo_afull;
	wire         processed_vid_fifo_empty;
	
	wire [7:0]   joiner_mpeg_out;
	wire         joiner_mpeg_wr;
	wire         joiner_vid_rd;
	wire         joiner_misc_rd;
	
	wire         output_fifo_afull;
	
	assign rst_200 = ~rst_n_200;
	assign rst_300 = ~rst_n_300;
	
	
`ifndef DES
	assign des_out = dese64_sign_out;
	assign des_busy = 1'b0;
	assign des_wr = dese64_des_wr;
`endif
  
	// IBUFDS IBUFDS_inst(
		// .I(clk_p),
        // .IB(clk_n),
        // .O(clk) 
	// );
	
	`ifdef DEBUG
	assign clk_200 = clk;
	assign clk_300 = clk2x;
	assign vlc_sign_bit = video_sign_bit;
	assign mb_ser_sign_bit = mb_ser_sign_out;
	assign post_des_ser_sign_bit = post_des_ser_sign_out;
	assign post_unscr_ser_sign_bit = post_unscr_ser_bit_out;
	`endif
	
	`ifdef DEBUG
	always @(posedge clk)
		if(~rst_n_200)               vid_cnt <= 32'h0;
		else if(splitter_vid_wr) vid_cnt <= vid_cnt + 1;
		else                     vid_cnt <= vid_cnt;
	
	always @(posedge clk)
		if(~rst_n_200)                misc_in_cnt <= 32'h0;
		else if(splitter_misc_wr) misc_in_cnt <= misc_in_cnt + 1;
		else                      misc_in_cnt <= misc_in_cnt;

	always @(posedge clk)
		if(~rst_n_200)                      			 vbuf_out_cnt <= 32'h0;
		else if(getbits_vbuf_rd && ~vbuf_fifo_empty) vbuf_out_cnt <= vbuf_out_cnt + 8;
		else                            			 vbuf_out_cnt <= vbuf_out_cnt;
	
	always @(posedge clk)
		if(~rst_n_200)         	     vlc_cnt_bit <= 31'h0;
		else if(video_align_reg) vlc_cnt_bit <= { vlc_cnt_bit[31:3] + 1, 3'h0};
		else                     vlc_cnt_bit <= vlc_cnt_bit + video_advance_reg;
	
	always @(posedge clk)
		if(~rst_n_200)          sign_cnt_cnt <= 32'h0;
		else if(counter_cnt_wr) sign_cnt_cnt <= sign_cnt_cnt + counter_cnt_out;
		else                    sign_cnt_cnt <= sign_cnt_cnt;
		
	always @(posedge clk)
		if(~rst_n_200)                 sign_switch_cnt <= 32'd0;
		else if(switcher_count_out_wr) sign_switch_cnt <= sign_switch_cnt + switcher_count_out[6:0];
		else                           sign_switch_cnt <= sign_switch_cnt;
	
	always @(posedge clk2x)
		if(~rst_n_300)                 replacer_sign_cnt <= 32'h0;
		else if(replacer_sign_data_wr) replacer_sign_cnt <= replacer_sign_cnt + 1;
		else                           replacer_sign_cnt <= replacer_sign_cnt;
	
	always @(posedge clk)
		if(~rst_n_200)             vlc_sign_cnt <= 32'd0;
		else if(video_sign_en) vlc_sign_cnt <= vlc_sign_cnt + 1;
		else                   vlc_sign_cnt <= vlc_sign_cnt;
	
	always @(posedge clk)
		if(~rst_n_200)              collator_sign_cnt <= 32'd0;
		else if(collator_mb_wr) collator_sign_cnt <= collator_sign_cnt + collator_scrambled_count;
		else                    collator_sign_cnt <= collator_sign_cnt;

	always @(posedge clk2x)
		if(~rst_n_300)             mb_ser_sign_cnt <= 32'd0;
		else if(mb_ser_out_wr) mb_ser_sign_cnt <= mb_ser_sign_cnt + 1;
		else                   mb_ser_sign_cnt <= mb_ser_sign_cnt;	
		
	always @(posedge clk2x)
		if(~rst_n_300)                     dese64_sign_cnt <= 32'd0;
		else if(dese64_des_wr)         dese64_sign_cnt <= dese64_sign_cnt + 64;
		else if(post_des_ser_last_ack) dese64_sign_cnt <= dese64_sign_cnt + dese64_size_out;
		else                           dese64_sign_cnt <= dese64_sign_cnt;
		
	always @(posedge clk2x)
		if(~rst_n_300)                    post_des_sign_cnt <= 32'd0;
		else if(post_des_ser_sign_en) post_des_sign_cnt <= post_des_sign_cnt + 1;
		else                          post_des_sign_cnt <= post_des_sign_cnt;
		
	always @(posedge clk2x)
		if(~rst_n_300)              unscrambler_sign_cnt <= 32'd0;
		else if(unscrambler_wr) unscrambler_sign_cnt <= unscrambler_sign_cnt + unscrambler_size;
		else                    unscrambler_sign_cnt <= unscrambler_sign_cnt;
	
	always @(posedge clk2x)
		if(~rst_n_300)                     post_unscr_ser_sign_cnt <= 32'd0;
		else if(post_unscr_ser_bit_wr) post_unscr_ser_sign_cnt <= post_unscr_ser_sign_cnt + 1;
		else                           post_unscr_ser_sign_cnt <= post_unscr_ser_sign_cnt;
		

	assign vlc_cnt_byte = vlc_cnt_bit[31:3];
	assign vlc_cnt_rem = vlc_cnt_bit[2:0];
  
	assign sign_cnt_cnt_byte = sign_cnt_cnt[31:3];
	assign sign_cnt_cnt_rem = sign_cnt_cnt[2:0];
  
	assign sign_switch_cnt_byte = sign_switch_cnt[31:3];
	assign sign_switch_cnt_rem = sign_switch_cnt[2:0];

	`endif
	
	mpeg_fifo mpeg_fifo_inst(
        .clk(clk_200),
		.srst(rst_200),
		
        .din(mpeg_in),
		.wr_en(mpeg_wr),
		.prog_full(mpeg_prog_full),
		.full(mpeg_full),
		
        .dout(mpeg_fifo_dout),
        .rd_en(splitter_mpeg_rd),
		.empty(mpeg_fifo_empty)
	);
	
	splitter splitter_inst(
		.clk(clk_200),
		.clk_en(clk_en),
		.rst(rst_n_200),
		
		.stream_in(mpeg_fifo_dout),
		.stream_empty(mpeg_fifo_empty),
		.vid_afull(vid_fifo_afull),
		.misc_afull(misc_fifo_afull),
		.vbuf_afull(vbuf_fifo_afull),
		
		.stream_end_in(stream_end),
		.stream_end_out(splitter_stream_end),
		
		.stream_out(splitter_stream_out),
		.stream_rd(splitter_mpeg_rd),
		
		.vid_wr(splitter_vid_wr),
		.misc_wr(splitter_misc_wr)
	);
	
	vid_fifo vid_fifo_inst(
		.wr_clk(clk_200),
		.din(splitter_stream_out),
		.wr_en(splitter_vid_wr),
		//.almost_full(vid_fifo_afull),
		.prog_full(vid_fifo_afull),
		
		.rd_clk(clk_300),
		.dout(vid_fifo_dout),
		.rd_en(replacer_sign_vid_rd),
		.empty(vid_fifo_empty),
		
		.rst(rst_200)
	);
	
	misc_fifo misc_fifo_inst(
        .clk(clk_200),
		.srst(rst_200),
		
        .din(splitter_stream_out),
		.wr_en(splitter_misc_wr),
		.almost_full(misc_fifo_afull),
		
        .dout(misc_fifo_dout),
        .rd_en(joiner_misc_rd),
		.empty(misc_fifo_empty)
	);
	
	video_extender extender_inst(
		.clk(clk_200),
		.clk_en(clk_en),
		.rst(rst_n_200),
		.stream_end(splitter_stream_end),
		
		.vbuf_in(splitter_stream_out),
		.vbuf_wr_in(splitter_vid_wr),
		
		.vbuf_out(extender_out),
		.vbuf_wr_out(extender_wr_out)
	);
	//overflow warning extender to vbuf on stream_end
		
	vbuf_fifo vbuf(
        .clk(clk_200),
        .srst(rst_200),
		
        .din(extender_out),
		.wr_en(extender_wr_out),
		.almost_full(vbuf_fifo_afull),
		
        .dout(vbuf_fifo_dout),
        .rd_en(getbits_vbuf_rd),
        .empty(vbuf_fifo_empty)
	);
		
  getbits getbits_inst
       (.clk(clk_200),
        .clk_en(clk_en),
		.rst(rst_n_200),
		
        .vid_in(vbuf_fifo_dout),
        .vid_in_empty(vbuf_fifo_empty),
        .vid_in_rd_en(getbits_vbuf_rd),
		
		.advance(video_advance),
        .align(video_align),
		
		.mb_fifo_afull(mb_fifo_afull),
		.mb_conf_fifo_afull(mb_conf_fifo_afull),
        .sign_counter_fifo_afull(sign_counter_fifo_afull),
        .extend_counter_fifo_afull(1'b0),
		
        .getbits(getbits_out),        
        .vld_en(getbits_vld_en)
	);
		
	video video_inst(
		.clk(clk_200),
        .clk_en(clk_en),
        .rst(rst_n_200),
		
		.getbits(getbits_out),
		.vld_en(getbits_vld_en),
		
		.advance(video_advance),
		.align(video_align),
        .advance_reg(video_advance_reg),
        .align_reg(video_align_reg),
        
        
        .extend_en(video_extend_en),
        
        .sign_en(video_sign_en),
        .sign_loc(video_sign_loc),
		.sign_bit(video_sign_bit),
        
        .group_change(video_group_change),
		.macroblock_end(video_macroblock_end),
		.slice_end(video_slice_end)
    );
	
	collator collator_inst(
		.clk(clk_200), 
		.clk_en(clk_en), 
		.rst(rst_n_200), 
		.sign_en(video_sign_en), 
		.sign_bit(video_sign_bit), 
		.group_change(video_group_change), 
		.macroblock_end(video_macroblock_end), 
		.slice_end(video_slice_end), 
		.mb_conf(collator_mb_conf), 
		.first_group(collator_first_group),
		.has_one_group(collator_has_one_group),
		.scrambled_plaintext(collator_scrambled_plaintext), 
		.original_position(collator_original_position),
		.scrambled_count(collator_scrambled_count),
		.no_sign(collator_no_sign),
		.mb_wr(collator_mb_wr),
		.mb_conf_wr(collator_mb_conf_wr)
	);
	
	mb_fifo mb_fifo_inst(
        .wr_clk(clk_200),
		.din({collator_scrambled_plaintext, collator_original_position, collator_scrambled_count, video_slice_end, collator_no_sign}),
		.wr_en(collator_mb_wr), 
		//.almost_full(mb_fifo_afull),
		.prog_full(mb_fifo_afull),
		
		.rd_clk(clk_300),
        .dout(mb_fifo_dout),
        .rd_en(mb_ser_mb_rd), 
        .empty(mb_fifo_empty),
        .rst(rst_200)
	);
	
	mb_conf_fifo mb_conf_fifo_inst(
        .clk(clk_200),
        .srst(rst_200),
		
        .din( {collator_mb_conf, collator_first_group, collator_has_one_group} ),
		.wr_en(collator_mb_conf_wr),
		.almost_full(mb_conf_fifo_afull),
		
        .dout(mb_conf_fifo_dout),
        .rd_en(switcher_mb_conf_rd),
        .empty(mb_conf_fifo_empty)
	);
	
	/****************************************
	*sign path
	****************************************/
	mb_ser mb_ser_inst(
		.clk(clk_300), 
		.clk_en(clk_en), 
		.rst(rst_n_300),
    
		.sign_in(mb_fifo_dout[456:393]),
		.pos_in(mb_fifo_dout[392:9]),
		.size_in(mb_fifo_dout[8:2]),
		.slice_end(mb_fifo_dout[1]),
		.no_sign(mb_fifo_dout[0]),
		.mb_empty(mb_fifo_empty),
    
		.dese_full(dese64_last_wr),
		.pos_afull(bitpos_fifo_afull),
		.bit_prog_full(bit_fifo_prog_full),
    
		.mb_rd(mb_ser_mb_rd),
		.sign_out(mb_ser_sign_out),
		.pos_out(mb_ser_bitpos_out),
		.out_wr(mb_ser_out_wr),
		.slice_end_out(mb_ser_slice_end)
	);
	
	bitpos_fifo bitpos_fifo_inst(
        .clk(clk_300),
        .rst(rst_300),
		
        .din(mb_ser_bitpos_out),
		.wr_en(mb_ser_out_wr),
		//.almost_full(bitpos_fifo_afull),
		.prog_full(bitpos_fifo_afull),
		
        .dout(bitpos_fifo_dout),
        .rd_en(unscrambler_bitpos_rd),
        .empty(bitpos_fifo_empty)
	);
	
	dese64 dese64_inst(
		.clk(clk_300),
		.clk_en(clk_en),
		.rst(rst_n_300), 
		
		.sign_in(mb_ser_sign_out),
		.sign_wr(mb_ser_out_wr),
		.slice_end(mb_ser_slice_end),
		.last_ack(post_des_ser_last_ack),
		
		.sign_out(dese64_sign_out),
		.size_out(dese64_size_out),
		.des_wr(dese64_des_wr),
		.last_wr(dese64_last_wr)
	);
`ifdef DES
	DES_single des(
		.clk(clk_300),  
		.clk_en(clk_en),  
		.rst(rst_n_300), 
		.data_in(dese64_sign_out),  
		.data_en(dese64_des_wr), 
		.key_in(key_in), 
		.mode_in(mode_in),  
		.key_en(key_en), 
		.data_out(des_out),
		.des_busy(des_busy), 
		.des_wr(des_wr)
	);
`endif
	
	post_des_ser pos_des_ser_inst(
		.clk(clk_300),
		.clk_en(clk_en),
		.rst(rst_n_300),
		
		.des_in(des_out),
		.des_busy(des_busy),
		.des_wr(des_wr),
		.last_in(dese64_sign_out),
		.last_size(dese64_size_out),
		.last_filled(dese64_last_wr), 
		.last_ack(post_des_ser_last_ack), 
		.sign_out(post_des_ser_sign_out),
		.sign_en(post_des_ser_sign_en)
	);
	
	unscrambler unscrambler_inst(
		.clk(clk_300),
		.clk_en(clk_en),
		.rst(rst_n_300),
		
		.sign_in(post_des_ser_sign_out),
		.sign_en(post_des_ser_sign_en),
		.pos_in(bitpos_fifo_dout),
		.pos_empty(bitpos_fifo_empty),
		.pos_rd(unscrambler_bitpos_rd),
		.unscrambler_out(unscrambler_out),
		.unscrambler_size(unscrambler_size),
		.unscrambler_wr(unscrambler_wr)
	);
	
	unscrambled_fifo unscrambled_fifo_inst(
        .clk(clk_300),
        .srst(rst_300),
		
        .din( {unscrambler_out, unscrambler_size} ),
		.wr_en(unscrambler_wr),
		
        .dout(unscrambled_fifo_dout),
        .rd_en(post_unscr_ser_unscrambled_fifo_rd),
        .empty(unscrambled_fifo_empty)
	);
	
	post_unscr_ser post_unscr_ser_inst(
		.clk(clk_300),
		.clk_en(clk_en),
		.rst(rst_n_300),
		
		.data_in(unscrambled_fifo_dout[70:7]),
		.size_in(unscrambled_fifo_dout[6:0]),
		.unscrambled_empty(unscrambled_fifo_empty),
		
		.unscrambled_rd(post_unscr_ser_unscrambled_fifo_rd),
		.bit_out(post_unscr_ser_bit_out),
		.bit_wr(post_unscr_ser_bit_wr)
	);
	
	bit_fifo bit_fifo_inst(
		.clk(clk_300),
        .rst(rst_300),
		
        .din(post_unscr_ser_bit_out),
		.wr_en(post_unscr_ser_bit_wr),
		
        .dout(bit_fifo_dout),
        .rd_en(replacer_sign_sign_rd),
        .empty(bit_fifo_empty),
		
		.prog_full(bit_fifo_prog_full)
	);
	
	/****************************************
	*side path
	****************************************/
	
	counter sign_counter_inst(
		.clk(clk_200),
		.clk_en(clk_en),
		.rst(rst_n_200),
		.advance(video_advance_reg),
		.align(video_align_reg),
		.sign_en(video_sign_en),
        .extend_en(video_extend_en),
		.sign_loc(video_sign_loc),
		
        .sign_flag_out(counter_sign_flag_out),
        .extend_flag_out(counter_extend_flag_out),
		.cnt_out(counter_cnt_out),
		.cnt_wr(counter_cnt_wr)
	);
	
	sign_counter_fifo sign_counter_fifo_inst(
		.clk(clk_200),
		.srst(rst_200),
		
		.din({counter_sign_flag_out, counter_extend_flag_out, counter_cnt_out}),
		.wr_en(counter_cnt_wr),
		.almost_full(sign_counter_fifo_afull),
		
		.dout(sign_counter_fifo_dout),
		.rd_en(switcher_count_rd),
		.empty(sign_counter_fifo_empty)
	);
	
	switcher sign_switcher_inst(
		.clk(clk_200),
		.clk_en(clk_en),
		.rst(rst_n_200),
		
		.mb_conf(mb_conf_fifo_dout[94:4]),
		.first_group(mb_conf_fifo_dout[3:1]),
		.has_one_group(mb_conf_fifo_dout[0]),
		.mb_conf_empty(mb_conf_fifo_empty),
		
        .sign_flag(sign_counter_fifo_dout[8]),
        .extend_flag(sign_counter_fifo_dout[7]),
		.sign_count(sign_counter_fifo_dout[6:0]),
		.sign_count_empty(sign_counter_fifo_empty),
		.count_out_afull(count_out_fifo_afull),
		
		.mb_conf_rd(switcher_mb_conf_rd),
		.sign_count_rd(switcher_count_rd),
        
        .sign_flag_out(switcher_sign_flag_out),
        .extend_flag_out(switcher_extend_flag_out),
		.count_out(switcher_count_out),
		.count_out_wr(switcher_count_out_wr)
	);
	
	count_out_fifo count_out_fifo_inst(
		.wr_clk(clk_200),
		.din({switcher_sign_flag_out, switcher_extend_flag_out, switcher_count_out}),
		.wr_en(switcher_count_out_wr),
		//.almost_full(count_out_fifo_afull),
		.prog_full(count_out_fifo_afull),
		
		.rd_clk(clk_300),
		.dout(count_out_fifo_dout),
		.rd_en(replacer_sign_cnt_rd),
		.empty(count_out_fifo_empty),
		.rst(rst_200)
	);
	
	replacer replacer_sign_inst(
		.clk(clk_300),
		.clk_en(clk_en),
		.rst(rst_n_300),
		
		.vid_in(vid_fifo_dout),
        .sign_flag(count_out_fifo_dout[8]),
        .extend_flag(count_out_fifo_dout[7]),
		.cnt_in(count_out_fifo_dout[6:0]),
		.vid_empty(vid_fifo_empty),
		.cnt_empty(count_out_fifo_empty),
		.sign_in(bit_fifo_dout),
		.sign_empty(bit_fifo_empty),
		.out_afull(processed_vid_fifo_afull),
		
		.vid_rd(replacer_sign_vid_rd),
		.cnt_rd(replacer_sign_cnt_rd),
		.sign_rd(replacer_sign_sign_rd),
		
		.data_out(replacer_sign_data_out),
		.data_wr(replacer_sign_data_wr)
	);
	
	processed_vid_fifo processed_vid_fifo_inst(
		.wr_clk(clk_300),
		.din(replacer_sign_data_out),
		.wr_en(replacer_sign_data_wr),
		//.almost_full(processed_vid_fifo_afull),
		.prog_full(processed_vid_fifo_afull),
		
		.rd_clk(clk_200),
		.dout(processed_vid_fifo_dout),
		.rd_en(joiner_vid_rd),
		.empty(processed_vid_fifo_empty),
		
		.rst(rst_200)
	);
	
	joiner joiner_inst(
		.clk(clk_200),
		.clk_en(clk_en),
		.rst(rst_n_200),
		
		.vid_in(processed_vid_fifo_dout),
		.vid_empty(processed_vid_fifo_empty),
		.misc_in(misc_fifo_dout),
		.misc_empty(misc_fifo_empty),
		.output_afull(output_fifo_afull),
		
		.vid_rd(joiner_vid_rd),
		.misc_rd(joiner_misc_rd),
		
		.mpeg_out(joiner_mpeg_out),
		.mpeg_wr(joiner_mpeg_wr)
	);
	
	output_fifo output_fifo_inst(
		.clk(clk_200), 
		.din(joiner_mpeg_out),
		.wr_en(joiner_mpeg_wr),
		.almost_full(output_fifo_afull),
		
		.dout(mpeg_out), 
		.rd_en(mpeg_rd), 
		.empty(mpeg_empty), 
		.srst(rst_200)
	);

endmodule
