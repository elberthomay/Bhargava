//--------------------------------------
// encrypt data with des
// the module run 1 round per cycle, producing result after 16 cycle
//
// key and mode is programmed with high pulse of key_en
// key_en must stay deasserted during normal operation
// assert key_en when des_busy is low
//
// encryption is initiated with high pulse of data_en
// data_en must stay deasserted while des_busy is asserted
//
// programming takes 2 clock cycle
//
// ciphertext is presented with assert pulse of des_wr
//
// pipelines
// key_in/mode_in -> initial_key/mode -> key_cd/cnt
// cnt -> shift_n -> key_cd -> data_reg
//--------------------------------------

module DES_single(
	input        clk, clk_en, rst,
	input [63:0] data_in, 
	input        data_en,
	input [63:0] key_in,
	input        mode_in, 
	input        key_en,
	
	output logic [63:0] data_out, 
	output logic        des_busy, 
	output logic        des_wr
);
	
	logic        mode;
	
	logic [63:0] data_reg;
	
	logic [55:0] initial_key;
	logic [55:0] key_cd;
	logic [47:0] key;
	
	logic        state, next;
	logic  [3:0] cnt, next_cnt;
	logic        end_enq;
	logic        shift_n;
	
	parameter STATE_IDLE = 1'b0, STATE_ENQ = 1'b1;
	
	`include "DES_func.sv"
	
	//initial_key
	always_ff @(posedge clk)
		//if(~rst)                  initial_key <= 56'h0;
		if(clk_en && key_en) initial_key <= mode_in ? PC1(key_in) : DES_key_cd_shift(PC1(key_in), 1'b0, 1'b0);
		else                 initial_key <= initial_key;
		
	//mode
	always_ff @(posedge clk)
		if(~rst)                  mode <= 1'b0;
		else if(clk_en && key_en) mode <= mode_in;
		else                      mode <= mode;
		
	//data_reg
	always_ff @(posedge clk)
		//if(~rst)                   data_reg <= 1'b0;
		if(clk_en && data_en) data_reg <= IP(data_in);
		else if(clk_en)       data_reg <= DES_round(data_reg, key);
		else                  data_reg <= data_reg;
	
	//key_cd
	always_ff @(posedge clk)
		//if(~rst) key_cd <= 56'h0;
		if(clk_en && state == STATE_IDLE)     key_cd <= initial_key;
		else if(clk_en && state == STATE_ENQ) key_cd <= DES_key_cd_shift(key_cd, mode, shift_n);
		else                                  key_cd <= key_cd;
	
	//key
	always_comb key = PC2(key_cd);
	
	// always_ff @(posedge clk)
		//if(~rst)   key <= 48'h0;
		// if(clk_en) key <= state? PC2(key_cd) : PC2(initial_key);
		// else       key <= key;
		
	//next
	always_comb begin
		casez(state)
			STATE_IDLE : next = data_en? STATE_ENQ : STATE_IDLE;
			STATE_ENQ  : next = end_enq ? STATE_IDLE : STATE_ENQ;
		endcase
	end
	
	//state
	always_ff @(posedge clk)
		if(~rst)        state <= STATE_IDLE;
		else if(clk_en) state <= next;
		else            state <= state;
	
	//end_enq
	always_ff @(posedge clk)
		if(~rst)        end_enq <= 1'b0;
		else if(clk_en) end_enq <= (~mode && cnt == 4'd1) || (mode && cnt == 4'd15);
		else            end_enq <= end_enq;
		
	//next_cnt
	always_comb begin
		casez(state)
			STATE_IDLE : next_cnt = mode? 4'd14 : 4'd2;
			STATE_ENQ  : next_cnt = mode? cnt - 1 : cnt + 1;
		endcase
	end
		
	//cnt
	always @(posedge clk)
		if(~rst)        cnt <= 4'd2;
		else if(clk_en) cnt <= next_cnt;
		else            cnt <= cnt;
		
	//shift_n
	always_ff @(posedge clk)
		//if(~rst) shift_n <= 1'b0;
		if(clk_en && state == STATE_IDLE)     shift_n <= 1'b0;
		else if(clk_en && state == STATE_ENQ) shift_n <= count_to_shift_n(cnt);
		else                                  shift_n <= shift_n;
	
	//data_out
	always_ff @(posedge clk)
		if(~rst)                   data_out  <= 64'h0;
		else if(clk_en && end_enq) data_out <= IP_inv( {data_reg[31:0], data_reg[63:32]} );
		else                       data_out <= data_out;
		
	//des_busy
	always_ff @(posedge clk)
		if(~rst)        des_busy <= 1'b0;
		else if(clk_en) des_busy <= data_en || (des_busy && ~end_enq);
		else            des_busy <= des_busy;
		
	//des_wr
	always_ff @(posedge clk)
		if(~rst)        des_wr <= 1'b0;
		else if(clk_en) des_wr <= end_enq;
		else            des_wr <= des_wr;
	
endmodule

module DES_pipeline(
	input        clk, clk_en, rst,
	input [63:0] data_in,
	input        data_in_en,
	input [63:0] key_in,
	input        mode_in,
	input        key_en,
	
	output logic [63:0] data_out,
	output logic        des_busy,
	output logic        data_out_en
	
);
	logic [55:0]       key_cd;
	wire [0:15][47:0]  key = generate_key(key_cd);
	
	logic              mode;
	logic [0:14][63:0] data_pipeline;
	logic [0:14]       pipeline_valid;
	logic [3:0]        valid_cnt;
	
	always_ff @(posedge clk)
		if(~rst)                  key_cd <= 56'h0;
		else if(clk_en && key_en) key_cd <= PC1(key_in);
		else                      key_cd <= key_cd;
		
	always_ff @(posedge clk)
		if(~rst)                  mode <= 1'b0;
		else if(clk_en && key_en) mode <= mode_in;
		else                      mode <= mode;
		
	always_ff @(posedge clk)
		if(clk_en) data_pipeline[0] <= DES_round(IP(data_in), (mode? key[15] : key[0]) );
		else       data_pipeline[0] <= data_pipeline[0];
		
	generate for(genvar i = 1; i < 15; i++)
		always_ff @(posedge clk)
			if(clk_en) data_pipeline[i] <= DES_round(data_pipeline[i-1], (mode? key[15-i] : key[i]) );
			else       data_pipeline[i] <= data_pipeline[i];
	endgenerate
	
	always_ff @(posedge clk)
		if(clk_en) data_out <= IP_inv(reverse_lr(DES_round(data_pipeline[14], (mode? key[0] : key[15]) ) ) );
		else       data_out <= data_out;
		
	always_ff @(posedge clk)
		if(~rst)        pipeline_valid <= 15'h0;
		else if(clk_en) pipeline_valid <= {data_in_en, pipeline_valid[0:14]};
		else            pipeline_valid <= pipeline_valid;
		
	always_ff @(posedge clk)
		if(~rst)                                             valid_cnt <= 4'd0;
		else if(clk_en && ~data_in_en && pipeline_valid[14]) valid_cnt <= valid_cnt + 1;
		else if(clk_en && data_in_en && ~pipeline_valid[14]) valid_cnt <= valid_cnt - 1;
		else                                                 valid_cnt <= valid_cnt;
		
	always_comb des_busy = valid_cnt != 4'd0;
		
	always_ff @(posedge clk)
		if(~rst)        data_out_en <= 1'b0;
		else if(clk_en) data_out_en <= pipeline_valid[14];
		else            data_out_en <= data_out_en;
endmodule