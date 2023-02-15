`timescale 1ns / 10ps
/*-----------------------------------------------------------------------------

Proprietary and Confidential Information

Module: PIFO_TOP.v
Author: Xiaoguang Li
Date  : 06/2/2019

Description: Top-level module that contains three levels of PIFO components. 

			 
Issues:  

-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------
module PIFO_TOP
#(
   parameter PTW    = 16,  // PRIORITY
   parameter MTW    = 32,  // METADATA
   parameter CTW    = 10,  // COUNT
   parameter LEVEL  = 6
)(
   // Clock and Reset
   input               i_clk,
   input               i_arst_n,
   
   // Push and Pop port to the whole PIFO tree
   input               i_push,
   input [(MTW+PTW)-1:0]  i_push_data,
   
   input               i_pop,
   output [(MTW+PTW)-1:0] o_pop_data      
);
//-----------------------------------------------------------------------------
// Include Files
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------


   wire [flat_max(LEVEL)-1:0]   push_in;
   wire [(MTW+PTW)-1:0]            push_data_in [0:flat_max(LEVEL)-1];
   wire [flat_max(LEVEL)-1:0]   pop_in;
   wire [(MTW+PTW)-1:0]            pop_data_in [0:flat_max(LEVEL)-1];
   wire [3:0]                   push_out [0:flat_max(LEVEL)-1];
   wire [(MTW+PTW)-1:0]            push_data_out [0:flat_max(LEVEL)-1];
   wire [3:0]                   pop_out [0:flat_max(LEVEL)-1];
   wire [4*(MTW+PTW)-1:0]          pop_data_out [0:flat_max(LEVEL)-1];
   
   
   wire [(MTW+PTW)-1:0]            result [0:flat_max(LEVEL)-1];
      
   integer test=1;
   integer n_result;   
//-----------------------------------------------------------------------------
// Instantiations
//-----------------------------------------------------------------------------

generate
   for (genvar i=0;i<LEVEL;i=i+1) begin
      for (genvar j=0;j<4**i;j=j+1) begin
         PIFO u_PIFO
         (
            .i_clk           ( i_clk                        ),
            .i_arst_n        ( i_arst_n                     ),
            .i_push          ( push_in[flat_idx(i,j)]       ),
            .i_push_data     ( push_data_in[flat_idx(i,j)]  ),
            .i_pop           ( pop_in[flat_idx(i,j)]        ),
            .o_pop_data      ( pop_data_in[flat_idx(i,j)]   ),
            .o_result      ( result[flat_idx(i,j)]   ),
            .o_push          ( push_out[flat_idx(i,j)]      ),
            .o_push_data     ( push_data_out[flat_idx(i,j)] ),
            .o_pop           ( pop_out[flat_idx(i,j)]       ),
            .i_pop_data      ( pop_data_out[flat_idx(i,j)]  )
         );
      end
   end
   for (genvar i=1;i<flat_max(LEVEL);i=i+1) begin
      assign push_in[i]            = push_out[(i-1)/4][(i-1)%4];
      assign push_data_in[i]       = push_data_out[(i-1)/4];
      assign pop_in[i]             = pop_out[(i-1)/4][(i-1)%4];
      assign pop_data_out[(i-1)/4][(MTW+PTW)*((i-1)%4+1)-1:(MTW+PTW)*((i-1)%4)] = pop_data_in[i];
	  if (find_level(i)==(LEVEL-1)) begin
         assign pop_data_out[i] = {4*(MTW+PTW){1'b1}};
	  end
   end   
endgenerate

assign push_in[0]                       = i_push;
assign push_data_in[0]                  = i_push_data;
assign pop_in[0]                        = i_pop;
assign o_pop_data                       = result[0];
//-----------------------------------------------------------------------------
// Functions and Tasks
//-----------------------------------------------------------------------------
function integer flat_idx;
input integer a;
input integer b;
integer i,j,k;
begin
   k=0;
   for (i=0;i<LEVEL;i=i+1) begin
      for (j=0;j<4**i;j=j+1) begin
		 if (a==i && b==j) begin
		    flat_idx = k;
		 end else begin
		    flat_idx = flat_idx;
		 end
		 k=k+1;
	  end
   end
end
endfunction

function integer flat_max;
input integer a;
integer i,j,k;
k=0;
begin
   for (i=0;i<a;i=i+1) begin
      for (j=0;j<4**i;j=j+1) begin
	     k=k+1;
      end	  
   end
   flat_max = k;
end 
endfunction

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

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------
//assign result = test%(4**(find_level(test)-1))-1;
assign n_result = 1%(4**(find_level(1)-1));

//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------

endmodule
