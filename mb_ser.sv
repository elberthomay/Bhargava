module mb_ser(
    input logic         clk, 
	input logic         clk_en, 
	input logic         rst,
    
    input        [63:0] sign_in,
    input [63:0] [5:0]  pos_in,
    input        [6:0]  size_in,
	input               slice_end,
	input               no_sign,
    input               mb_empty,
    
    input logic         dese_full,
    input logic         pos_afull,
	input logic         bit_prog_full,
    
    output logic        mb_rd,
	output logic        sign_out,
	output logic [6:0]  pos_out,
    output logic        out_wr,
	output logic        slice_end_out
);
    //logic               mb_ready0;
    logic               mb_ready;
	logic               mb_reg_ready;
	logic               slice_end_reg; 
    logic        [63:0] sign_reg;
    logic  [63:0][5:0]  pos_reg;
    logic        [6:0]  size_reg;
    
    
    logic        [5:0]  cnt;
	
	logic               last_in_mb;
    logic               next_mb_wr;
	
	/*
	//mb_ready0
    always_ff @(posedge clk)
        if(~rst)        mb_ready0 <= 1'b0;
        else if(clk_en) mb_ready0 <= (mb_rd && ~mb_empty) || (mb_ready0 && ~mb_rd);
        else            mb_ready0 <= mb_ready0;
		
	//mb_ready
	always_ff @(posedge clk)
		if(~rst)        mb_ready <= 1'b0;
		else if(clk_en) mb_ready <= (mb_ready0 && mb_rd) || (mb_ready && mb_reg_ready);
		else            mb_ready <= mb_ready;
		
	*/
	
	
	//mb_ready
	always_ff @(posedge clk)
		if(~rst)        mb_ready <= 1'b0;
		else if(clk_en) mb_ready <= mb_rd || (mb_ready && mb_reg_ready);
		else            mb_ready <= mb_ready;
	
	
		
	//mb_reg_ready
	always_ff @(posedge clk)
		if(~rst)        mb_reg_ready <= 1'b0;
		else if(clk_en) mb_reg_ready <= (~mb_reg_ready && mb_ready && ~no_sign) || (mb_reg_ready && ~(size_reg == 7'd1 && next_mb_wr));
		else            mb_reg_ready <= mb_reg_ready;
		
	//slice_end_reg
	always_ff @(posedge clk)
		if(~rst)                                     slice_end_reg <= 1'b0;
		else if(clk_en && ~mb_reg_ready && mb_ready) slice_end_reg <= slice_end;
		else if(clk_en && ~mb_reg_ready)             slice_end_reg <= 1'b0;
		else                                         slice_end_reg <= slice_end_reg;
		
    
	//sign_reg
	always_ff @(posedge clk)
		//if(~rst)                                sign_reg <= 64'h0;
		if(clk_en && ~mb_reg_ready && mb_ready) sign_reg <= sign_in;
		else if(clk_en && next_mb_wr)           sign_reg <= {sign_reg[62:0], 1'b0};
		else                                    sign_reg <= sign_reg;
		
	//pos_reg
	always_ff @(posedge clk)
	    //if(~rst)                                pos_reg <= 64'h0;
		if(clk_en && ~mb_reg_ready && mb_ready) pos_reg <= pos_in;
		else if(clk_en && next_mb_wr)           pos_reg <= {pos_reg[62:0], 6'd0};
		else                                    pos_reg <= pos_reg;
	
    //size_reg
    always_ff @(posedge clk)
        //if(~rst)                                size_reg <= 7'd0;
        if(clk_en && ~mb_reg_ready && mb_ready) size_reg <= size_in;
        else if(clk_en && next_mb_wr)           size_reg <= size_reg - 1;
        else                                    size_reg <= size_reg;
	
    //cnt
    always_ff @(posedge clk)
        if(~rst || (clk_en && ~mb_ready) ) cnt <= 6'd0;
        else if(clk_en && next_mb_wr)      cnt <= cnt + 1;
        else                               cnt <= cnt;
	
	//last_in_mb
	always_ff @(posedge clk)
		if(~rst)        last_in_mb <= 1'b0;
		else if(clk_en) last_in_mb <= (mb_ready && ~mb_reg_ready && size_in == 7'd1) || (size_reg == 7'd2 && next_mb_wr) || (last_in_mb && ~next_mb_wr);
		else            last_in_mb <= last_in_mb;
        
    //sign_out
    always_ff @(posedge clk)
        if(~rst)                      sign_out <= 1'b0;
        else if(clk_en && next_mb_wr) sign_out <= sign_reg[63];
		else                          sign_out <= sign_out;
        
    //pos_out
	always_ff @(posedge clk)
		if(~rst)                      pos_out <= 7'h0;
		else if(clk_en && next_mb_wr) pos_out <= {last_in_mb, pos_reg[63]};
		else                          pos_out <= pos_out;
    
    //out_wr
	always_ff @(posedge clk)
		if(~rst)        out_wr <= 1'b0;
		else if(clk_en) out_wr <= next_mb_wr;
		else            out_wr <= 1'b0;
		
	//slice_end_out
	always_ff @(posedge clk)
		if(~rst) slice_end_out <= 1'b0;
		else if(clk_en && ~mb_reg_ready) slice_end_out <= slice_end_reg;
		else if(clk_en)                  slice_end_out <= 1'b0;
		else                             slice_end_out <= slice_end_out;
	
	assign next_mb_wr = mb_reg_ready && ~dese_full && ~pos_afull && ~bit_prog_full;
	assign mb_rd = clk_en && ~mb_empty && ~mb_ready;
endmodule