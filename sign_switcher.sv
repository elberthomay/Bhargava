module sign_switcher(
	input        clk, clk_en, rst,
	
	input [90:0] mb_conf,					// number of sign on each group(13*7 bit) motion, selected g1, unselected g1, selected g2... unselected g6;
	input [2:0]  first_group,				// first group with sign
	input        has_one_group,				// there's only 1 group with sign in mb
	input        mb_conf_empty,				// empty flag of mb_conf_fifo
	
	input [7:0]  sign_count,				// sign_count input {[7]:has_sign, [6:0]:count}
	input        sign_count_empty, 			// empty flag of sign_count_fifo
	
	input        count_out_afull, 			// almost_full flag of count_out
	
	output logic       mb_conf_rd, 			// rd flag to mb_conf_fifo
	output logic       sign_count_rd, 		// rd flag to sign_count_fifo
	output logic [7:0] count_out, 			// count_out output
	output logic       count_out_wr 		// write flag to count_out_fifo
);
	logic mb_conf_ready;					// valid flag of mb_conf, internally managed
	logic sign_count_ready;					// valid flag of sign_count, internally managed
	
	logic [0:12][6:0] mb_conf_reg;			// mb_conf working space
	logic             mb_conf_reg_ready;	// mb_conf and group value ready
	
	logic [0:12]      group_empty;			// asserted if corresponding group is empty or current group
	logic [0:12]      current_group;		// one-hot, indicate current group
	logic [0:12]      next_group;
	logic             last_group;			// asserted if current group is last in mb
	
	
	logic             next_count_out_wr;
	
	logic [6:0]       current_conf;
	
	logic             switch;
	

	
	
	//mb_conf_ready
	always_ff @(posedge clk)
		if(~rst)        mb_conf_ready <= 1'b0;
		else if(clk_en) mb_conf_ready <= (mb_conf_rd && ~mb_conf_empty) || (mb_conf_ready && mb_conf_reg_ready);
		else            mb_conf_ready <= mb_conf_ready;
		
	//sign_count_ready
	always_ff @(posedge clk)
		if(~rst)        sign_count_ready <= 1'b0;
		else if(clk_en) sign_count_ready <= (sign_count_rd && ~sign_count_empty) || (sign_count_ready && ~next_count_out_wr);
		else            sign_count_ready <= sign_count_ready;
	
	//mb_conf_reg
	generate for(genvar i = 0; i < 13; i++)
		always_ff @(posedge clk)
			//if(~rst) mb_conf_reg[i] <= 7'b0;
			if(clk_en && ~mb_conf_reg_ready && mb_conf_ready) mb_conf_reg[i] <= mb_conf[90-i*7 -: 7];
			else if(clk_en && current_group[i] &&             //
			        next_count_out_wr && sign_count[7])       mb_conf_reg[i] <= mb_conf_reg[i] - 1;
			else                                              mb_conf_reg[i] <= mb_conf_reg[i];
	endgenerate
			
	//mb_conf_reg_ready
	always_ff @(posedge clk)
		if(~rst)        mb_conf_reg_ready <= 1'b0;
		else if(clk_en) mb_conf_reg_ready <= (mb_conf_ready && ~mb_conf_reg_ready) || (mb_conf_reg_ready && ~(last_group && current_conf == 6'd1 && next_count_out_wr && sign_count[7]) );
		else            mb_conf_reg_ready <= mb_conf_reg_ready;
		
	//group_empty
	always_ff @(posedge clk) group_empty[0] <= 1'b1;
			
	generate 
		for(genvar i = 1; i < 2; i++)
			always_ff @(posedge clk)
				//if(~rst) group_empty[i] <= 1'b1;
				if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                                                  group_empty[i] <= mb_conf[90-i*7 -: 7] == 7'd0 || (i == first_group);
				else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7] && &group_empty[0 +: i]) group_empty[i] <= 1'b1;
				else                                                                                               group_empty[i] <= group_empty[i];
		
		for(genvar i = 3; i < 13; i = i+2)
			always_ff @(posedge clk)
				//if(~rst) group_empty[i] <= 1'b1;
				if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                                                  group_empty[i] <= mb_conf[90-i*7 -: 7] == 7'd0 || (first_group * 2 == (i+1));
				else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7] && &group_empty[0 +: i]) group_empty[i] <= 1'b1;
				else                                                                                               group_empty[i] <= group_empty[i];
				
		for(genvar i = 2; i < 13; i = i+2)
			always_ff @(posedge clk)
				//if(~rst) group_empty[i] <= 1'b1;
				if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                                                  group_empty[i] <= mb_conf[90-i*7 -: 7] == 7'd0;
				else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7] && &group_empty[0 +: i]) group_empty[i] <= 1'b1;
				else                                                                                               group_empty[i] <= group_empty[i];


	endgenerate
	
	//next_group
	always_comb next_group[0] = 1'b0;
	generate for(genvar i = 1; i < 13; i++)
		always_comb next_group[i] = &group_empty[0 +: i] && ~group_empty[i];
	endgenerate
	
	//current_group
	generate 
		for(genvar i = 0; i < 2; i++)
			always_ff @(posedge clk)
				//if(~rst) current_group[i] <= 1'b0;
				if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                          current_group[i] <= first_group == i;
				else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7]) current_group[i] <= next_group[i];
				else                                                                       current_group[i] <= current_group[i];
				
		for(genvar i = 3; i < 13; i = i+2)
			always_ff @(posedge clk)
				//if(~rst) current_group[i] <= 1'b0;
				if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                          current_group[i] <= first_group * 2 == (i+1);
				else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7]) current_group[i] <= next_group[i];
				else                                                                       current_group[i] <= current_group[i];
				
		for(genvar i = 2; i < 13; i = i+2)
			always_ff @(posedge clk)
				//if(~rst) current_group[i] <= 1'b0;
				if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                          current_group[i] <= 1'b0;
				else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7]) current_group[i] <= next_group[i];
				else                                                                       current_group[i] <= current_group[i];
		
	endgenerate
			
	//last_group
	always_ff @(posedge clk)
		//if(~rst) last_group <= 1'b0;
		if(clk_en && ~mb_conf_reg_ready && mb_conf_ready)                          last_group <= has_one_group;
		else if(clk_en && current_conf == 1 && next_count_out_wr && sign_count[7]) last_group <= is_one_cold_or_empty(group_empty);
		else                                                                       last_group <= last_group;
		
	//current_conf
	always_comb begin
		casez(current_group)
			13'b1_0000_0000_0000 : current_conf = mb_conf_reg[0];
			13'b0_1000_0000_0000 : current_conf = mb_conf_reg[1];
			13'b0_0100_0000_0000 : current_conf = mb_conf_reg[2];
			13'b0_0010_0000_0000 : current_conf = mb_conf_reg[3];
			13'b0_0001_0000_0000 : current_conf = mb_conf_reg[4];
			13'b0_0000_1000_0000 : current_conf = mb_conf_reg[5];
			13'b0_0000_0100_0000 : current_conf = mb_conf_reg[6];
			13'b0_0000_0010_0000 : current_conf = mb_conf_reg[7];
			13'b0_0000_0001_0000 : current_conf = mb_conf_reg[8];
			13'b0_0000_0000_1000 : current_conf = mb_conf_reg[9];
			13'b0_0000_0000_0100 : current_conf = mb_conf_reg[10];
			13'b0_0000_0000_0010 : current_conf = mb_conf_reg[11];
			13'b0_0000_0000_0001 : current_conf = mb_conf_reg[12];
			default                current_conf = mb_conf_reg[0];
		endcase
	end
	
	//is_one_cold_or_empty
	function logic is_one_cold_or_empty(input [0:12] group_empty);
		casez(group_empty)
			13'b0_1111_1111_1111,  
			13'b1_0111_1111_1111,  
			13'b1_1011_1111_1111,  
			13'b1_1101_1111_1111,  
			13'b1_1110_1111_1111,  
			13'b1_1111_0111_1111,  
			13'b1_1111_1011_1111,  
			13'b1_1111_1101_1111,  
			13'b1_1111_1110_1111,  
			13'b1_1111_1111_0111,  
			13'b1_1111_1111_1011,  
			13'b1_1111_1111_1101,  
			13'b1_1111_1111_1110,
			13'b1_1111_1111_1111 : is_one_cold_or_empty = 1'b1;
			default                is_one_cold_or_empty = 1'b0;
		endcase
	endfunction
	
	//switch
	always_comb switch = ~(current_group[2] || current_group[4] || current_group[6] || current_group[8] || current_group[10] || current_group[12]);
	
	
	//mb_conf_rd
	always_comb mb_conf_rd = ~mb_conf_ready && clk_en;
	
	//sign_count_rd
	always_comb sign_count_rd = (~sign_count_ready || next_count_out_wr) && clk_en;
	
	//count_out
	always_ff @(posedge clk)
		if(clk_en && next_count_out_wr) count_out <= {sign_count[7] && switch, sign_count[6:0]};
		else                            count_out <= count_out;
		
	//count_out_wr
	always_comb next_count_out_wr = (mb_conf_reg_ready || ~sign_count[7]) && sign_count_ready && ~count_out_afull;
	
	always_ff @(posedge clk)
		if(~rst)        count_out_wr <= 1'b0;
		else if(clk_en) count_out_wr <= next_count_out_wr;
		else            count_out_wr <= 1'b0;
		
endmodule