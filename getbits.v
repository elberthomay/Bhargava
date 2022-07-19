/* 
 * getbits.v
 * 
 * Copyright (c) 2007 Koen De Vleeschauwer. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND 
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS 
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
 * SUCH DAMAGE.
 */

/*
 * getbits - read bitfields from incoming video stream
 */


`undef DEBUG
//`define DEBUG 1

module getbits (clk, clk_en, rst, 
   vid_in, vid_in_rd_en, vid_in_empty,
   advance, align,
   getbits, getbits_valid,
   mb_fifo_afull, mb_conf_fifo_afull, sign_counter_fifo_afull, extend_counter_fifo_afull, vld_en); //,wait_state,

  input            clk;                      // clock
  input            clk_en;                   // clock enable
  input            rst;                      // synchronous active low reset

  input      [63:0]vid_in;
  output reg       vid_in_rd_en;
  input            vid_in_empty;

  input       [4:0]advance;                  // number of bits to advance the bitstream (advance <= 24). Enabled when getbits_valid asserted.
  input            align;                    // byte-align getbits and move forward one byte. Enabled when getbits_valid asserted.
  //input            wait_state;               // asserted if vld needs to be frozen next clock cycle.
  input            mb_fifo_afull;       
  input            mb_conf_fifo_afull;      
  input            sign_counter_fifo_afull;
  input            extend_counter_fifo_afull;

  output reg [23:0]getbits;                  // bit-aligned elementary stream data. 
  //output reg       signbit;                  // In table B-14 and B-15, the rightmost bit of the variable length code is the sign bit.
                                             // When decoding DCT variable length codes, signbit contains the sign bit of the
                                             // previous clock's coefficient.

  output reg       getbits_valid;            // getbits_valid is asserted when getbits is valid.
  output reg       vld_en;                   // vld clock enable

  reg       [127:0]dta;                      // 129 bits. No typo.
  reg       [103:0]dummy;                    // dummy variable, not used.
  reg         [7:0]cursor;
  reg       [127:0]next_dta;
  reg         [7:0]next_cursor;
  reg         [6:0]next_shift;
  reg        [23:0]next_getbits;
  //reg              next_signbit;
  reg              vid_in_rd_valid;
  reg              initial_state;

  parameter 
    STATE_SETUP     = 2'd0,
    STATE_INIT      = 2'd1,
    STATE_READY     = 2'd2;

  reg         [1:0] state, next;

  /* next state logic */
  always @*
    case (state)
	  STATE_SETUP: if(vid_in_rd_valid) next = STATE_INIT;
				   else next = STATE_SETUP;
      STATE_INIT:  if (vid_in_rd_valid && (next_cursor < 8'd64)) next = STATE_READY;
                   else next = STATE_INIT;

      STATE_READY: if (next_cursor > 63) next = STATE_INIT;
                   else next = STATE_READY;

      default      next = STATE_INIT;
    endcase

  /* state */
  always @(posedge clk)
    if(~rst) state <= STATE_SETUP;
    else if (clk_en) state <= next;
    else state <= state;

  /* registers */

  always @*
    if ( (state == STATE_SETUP || state == STATE_INIT) && vid_in_rd_valid) next_dta = {dta[64:0], vid_in};
    else next_dta = dta;

  //wire [7:0]cursor_aligned = {cursor[7:3], 3'b0};
  //wire [7:0]advance_ext = {3'b0, advance};

  always @* next_cursor = (align && vld_en? {cursor[7:3] + 1, 3'b0} : cursor) - ( (state == STATE_SETUP || state == STATE_INIT) && vid_in_rd_valid? 8'd64 : 8'd0) + 
						  (vld_en? advance : 8'd0);
  
  always @* next_shift = align && ~initial_state? {cursor[6:3] + 1, 3'b0} : cursor[6:0] + advance;

  always @*
    {next_getbits, dummy} = dta << next_shift;

  always @(posedge clk)
    if (~rst) dta <= 128'b0;
    else if (clk_en) dta <= next_dta;
    else dta <= dta;

  always @(posedge clk)
    if (~rst) cursor <= 8'd128;
    else if (clk_en) cursor <= next_cursor;
    else cursor <= cursor;

  // always @(posedge clk)
    // if (~rst) signbit <= 1'b0;
    // else if (clk_en) signbit <= next_signbit;
    // else signbit <= signbit;

  always @(posedge clk)
    if (~rst)                                     getbits <= 24'b0;
	//else if(clk_en && initial_state) getbits <= dta[63 -: 24];
    else if (clk_en && (vld_en || initial_state)) getbits <= next_getbits;
    else                                          getbits <= getbits;

  always @(posedge clk)
    if (~rst) getbits_valid <= 1'b0;
    else if (clk_en) getbits_valid <= (state != STATE_SETUP) && (next == STATE_READY || vid_in_rd_valid);
    else getbits_valid <= getbits_valid;

  always @* vid_in_rd_en = ~vid_in_rd_valid && clk_en;
	 
  always @(posedge clk)
    if (~rst)       vid_in_rd_valid <= 1'b0;
    else if(clk_en) vid_in_rd_valid <= (vid_in_rd_en && ~vid_in_empty) || (vid_in_rd_valid && state == STATE_READY);
	else            vid_in_rd_valid <= vid_in_rd_valid;

  /* vld clock enable */

  /*
   * variable length decoding and fifo take turns;
   * First vld determines how much to move forward in the bitstream;
   * next clock, getbits moves that amount forward in the stream while vld waits;
   * then vld analyzes the new position in the bitstream while getbits waits,
   * and so on.
   */
   
   always @(posedge clk)
	if(~rst)                               initial_state <= 1'b1;
	else if(clk_en && next == STATE_READY) initial_state <= 1'b0;
	else                                   initial_state <= initial_state;

  always @(posedge clk)
    if (~rst) vld_en <= 1'b0;
    // enable vld when getbits, rld, and motcomp ready, and not a wait state
    //else if (clk_en && vld_en) vld_en <= (next == STATE_READY) && ~wait_state && ~mb_fifo_afull && ~mb_conf_fifo_afull && ~sign_counter_fifo_afull;
    else if (clk_en) vld_en <= (state != STATE_SETUP) && (next == STATE_READY || vid_in_rd_valid) && ~mb_fifo_afull && ~mb_conf_fifo_afull && ~sign_counter_fifo_afull && ~extend_counter_fifo_afull;                
    else vld_en <= vld_en;

  /* Debugging */
`ifdef DEBUG
   always @(posedge clk)
     if (clk_en)
       $strobe("%m\tvid_in: %h vid_in_rd_en: %d vid_in_rd_valid: %d advance: %d align: %d state: %d dta: %h cursor: %h signbit: %d getbits: %h getbits_valid: %d ",
                    vid_in, vid_in_rd_en, vid_in_rd_valid, advance, align, state, dta, cursor, signbit, getbits, getbits_valid);
`endif

endmodule
/* not truncated */
