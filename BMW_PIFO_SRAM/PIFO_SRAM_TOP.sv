`timescale 1ns / 10ps
/*-----------------------------------------------------------------------------

Proprietary and Confidential Information

Module: PIFO_SRAM_TOP.v
Author: Xiaoguang Li
Date  : 06/16/2019

Description: Top-level module that contains n levels (n is parameterizable) 
             of PIFO components (In this version, PIFO storage elements are
			 SRAM instead of FFs. This makes the whole PIFO tree more expandable.). 
			 
Issues:  

-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------
module PIFO_SRAM_TOP
#(
   parameter PTW = 16,  // Payload data width
   parameter MTW    = 32,  // METADATA
   parameter CTW = 10,  // Sub-tree width
   parameter ADW  = 20, // ADDRESS WDITH
   parameter LEVEL  = 8 // Sub-tree level
)(
   // Clock and Reset
   input               i_clk,
   input               i_arst_n,
   
   // Push and Pop port to the whole PIFO tree
   input               i_push,
   input [(MTW+PTW)-1:0]     i_push_data,
   
   input               i_pop,
   output [(MTW+PTW)-1:0]    o_pop_data      
);
//-----------------------------------------------------------------------------
// Include Files
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Functions and Tasks
//-----------------------------------------------------------------------------


function integer find_level;
input integer a;
integer i,j,k;
begin
k=0;
find_level=0;
for (i=0;i<LEVEL;i=i+1) begin
   for (j=0;j<4**i;j=j+1) begin
      if (a==k) begin
		 find_level = i;
      end else begin
		 find_level = find_level;
      end
      k=k+1;     
   end
end
end
endfunction

function integer addr_idx_high;
input integer pifo_level;
integer i,j,k;
begin
   j=0;
   k=0;
   for (i=0;i<pifo_level;i=i+1) begin
      if (i==0) begin
         k=0;
	   end else begin
	     k=$clog2(4**i);
	   end
	   j=j+k;
   end
   addr_idx_high = j;
end
endfunction

function integer addr_idx_low;
input integer pifo_level;
integer i,j,k;
begin
   j=0;
   k=0;
   for (i=0;i<pifo_level;i=i+1) begin
      if (i==0) begin
         k=0;
	  end else begin
	     k=$clog2(4**(i-1));
	  end
	  j=j+k;
   end
   if (pifo_level == 1) begin
      addr_idx_low = 0;
   end else begin
      addr_idx_low = j+1;
   end
end
endfunction




//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------

   wire [LEVEL-1:0]    push_up;
   wire [(MTW+PTW)-1:0]                push_data_up [0:LEVEL-1];
   wire [LEVEL-1:0]    pop_up;
   wire [(MTW+PTW)-1:0]                pop_data_up  [0:LEVEL-1];
   wire                          push_dn      [0:LEVEL-1];
   wire [(MTW+PTW)-1:0]                push_data_dn [0:LEVEL-1];
   wire                          pop_dn       [0:LEVEL-1];
   wire [(MTW+PTW)-1:0]                pop_data_dn  [0:LEVEL-1];
   
   wire [LEVEL - 1:0]            read;
   wire [LEVEL - 1:0]            write;
   wire [4*(CTW+MTW+PTW)-1:0]        read_data    [0:LEVEL - 1];
   wire [4*(CTW+MTW+PTW)-1:0]        write_data   [0:LEVEL - 1];   
   
   wire [LEVEL-1:0]              we;
   wire [addr_idx_high(LEVEL):0] waddr;
   wire [4*(CTW+MTW+PTW)-1:0]        wdata        [0:LEVEL-1];
      
   wire [LEVEL-1:0]              re;
   wire [addr_idx_high(LEVEL):0] raddr;
   wire [4*(CTW+MTW+PTW)-1:0]        rdata        [0:LEVEL-1];   


   wire [ADW-1:0]                read_addr    [0:LEVEL-1];
   wire [ADW-1:0]                write_addr    [0:LEVEL-1];
   
   
   wire [ADW-1:0]                my_addr    [0:LEVEL-1];
   wire [ADW-1:0]                child_addr   [0:LEVEL-1];

       
   integer test=1;
   integer result;   
//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------
genvar i,j;
generate
   for (i=0;i<LEVEL;i=i+1) begin : pifo_loop
         PIFO_SRAM #(
		    .PTW (PTW),
          .MTW (MTW),
			.CTW (CTW),
         .ADW (ADW)
		 ) u_PIFO (
            .i_clk           ( i_clk                        ),
            .i_arst_n        ( i_arst_n                     ),

            .i_push          ( push_up      [i] ),
            .i_push_data     ( push_data_up [i] ),
            .i_pop           ( pop_up       [i] ),
            .o_pop_data      ( pop_data_up  [i] ),

            .o_push          ( push_dn      [i] ),
            .o_push_data     ( push_data_dn [i] ),
            .o_pop           ( pop_dn       [i] ),
            .i_pop_data      ( pop_data_dn  [i] ),
			
            .o_read          ( read         [i] ), 
            .i_read_data     ( read_data    [i] ), 
   
            .o_write         ( write        [i] ), 
            .o_write_data    ( write_data   [i] ),

            .i_my_addr       ( my_addr      [i] ),
            .o_child_addr    ( child_addr   [i] ),
            .o_read_addr     ( read_addr    [i] ),
            .o_write_addr    ( write_addr    [i] )		
         );
   end
   
   assign push_up[0]            = i_push;
   assign push_data_up[0]       = i_push_data;
   assign pop_up[0]             = i_pop;
   assign o_pop_data            = pop_data_up[0];
   assign my_addr[0]            = 1'b0;

   for (i=1;i<LEVEL;i=i+1) begin : loop1
      assign push_up[i]            = push_dn[i-1];
      assign push_data_up[i]       = push_data_dn[i-1];
      assign pop_up[i]             = pop_dn[i-1];
      assign pop_data_dn[i-1]      = pop_data_up[i];
      assign my_addr[i]            = child_addr[i - 1];
   end   
   assign pop_data_dn[LEVEL - 1] = {(MTW+PTW){1'b1}};
   




   
   for (i=1; i<LEVEL; i=i+1) begin : sram_inst
      INFER_SDPRAM #( 
	      .DATA_WIDTH ( 4*(CTW+MTW+PTW)                  ), 
         .ADDR_WIDTH ( 2 * i                         ), 
         .ARCH       ( 0                            ), 
         .RDW_MODE   ( 1                            ),
         .INIT_VALUE ( {4{{CTW{1'b0}},{(MTW+PTW){1'b1}}}} ) // Sub-tree size is zero. Pifo value are maximum initially.		 
	  ) u_INFER_SDPRAM 
	  (
         .i_clk      ( i_clk                                   ),     
         .i_arst_n   ( i_arst_n                                ),  

         .i_we       ( we[i]                                   ), 
         .i_waddr    ( waddr[addr_idx_high(i+1):addr_idx_low(i+1)] ),    //地址宽度
         .i_wdata    ( wdata[i]                                ), 

         .i_re       ( re[i]                                   ),                                        
         .i_raddr    ( raddr[addr_idx_high(i+1):addr_idx_low(i+1)] ),    
         .o_rdata    ( rdata[i]                                ) 
      );  

      assign re[i]    = read[i];
      assign we[i]    = write[i];
      assign waddr[addr_idx_high(i+1):addr_idx_low(i+1)] = write_addr[i];
      assign raddr[addr_idx_high(i+1):addr_idx_low(i+1)] = read_addr[i];	       
      assign wdata[i] = write_data[i];
   end     


      INFER_SDPRAM #( 
	      .DATA_WIDTH ( 4*(CTW+MTW+PTW)                  ), 
         .ADDR_WIDTH ( 2                         ), 
         .ARCH       ( 0                            ), 
         .RDW_MODE   ( 1                            ),
         .INIT_VALUE ( {4{{CTW{1'b0}},{(MTW+PTW){1'b1}}}} ) // Sub-tree size is zero. Pifo value are maximum initially.		 
	  ) SDPRAM0
	  (
         .i_clk      ( i_clk                                   ),     
         .i_arst_n   ( i_arst_n                                ),  

         .i_we       ( we[0]                                   ), 
         .i_waddr    ( waddr[addr_idx_high(1):addr_idx_low(1)] ),    //地址宽度
         .i_wdata    ( wdata[0]                                ), 

         .i_re       ( re[0]                                   ),                                        
         .i_raddr    ( raddr[addr_idx_high(1):addr_idx_low(1)] ),    
         .o_rdata    ( rdata[0]                                ) 
      );  

      assign re[0]    = read[0];
      assign we[0]    = write[0];
      assign waddr[addr_idx_high(2):addr_idx_low(2)] = write_addr[0];
      assign raddr[addr_idx_high(2):addr_idx_low(2)] = read_addr[0];	       
      assign wdata[0] = write_data[0];
   
   for (i=0;i<LEVEL;i=i+1) begin : loop
         assign read_data[i] = rdata[i];
   end




endgenerate

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------
//assign result = test%(4**(find_level(test)-1))-1;

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------

endmodule