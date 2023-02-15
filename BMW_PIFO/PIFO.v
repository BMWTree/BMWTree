`timescale 1ns / 10ps
/*-----------------------------------------------------------------------------
Proprietary and Confidential Information

Module: PIFO.v
Author: Zhiyu Zhang
Date  : 09/19/2022		 
-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------
module PIFO 
#(
   parameter PTW    = 16,  // PRIORITY
   parameter MTW    = 32,  // METADATA
   parameter CTW    = 10  // COUNT
)
(
   // Clock and Reset
   input                      i_clk,         // I - Clock
   input                      i_arst_n,      // I - Active Low Async Reset

   // From/To Parent 
   input                      i_push,        // I - Push Command from Parent
   input  [(MTW+PTW)-1:0]     i_push_data,   // I - Push Data from Parent 
   input                      i_pop,         // I - Pop Command from Parent
   output reg [(MTW+PTW)-1:0] o_pop_data,    // O - Pop Data from Parent

   // From/To Child
   output reg [3:0]           o_push,        // O - Push Command to Child
   output reg [(MTW+PTW)-1:0] o_push_data,   // O - Push Data to Child
   output reg [3:0]           o_pop,         // O - Pop Command to Child   
   input  [4*(MTW+PTW)-1:0]   i_pop_data,    // I - Pop Data from Child
   output reg [(MTW+PTW)-1:0] o_result    
);

//-----------------------------------------------------------------------------
// Register and Wire Declarations
//-----------------------------------------------------------------------------

   reg [(MTW+PTW)-1:0]      latch_data;
   reg [(CTW+MTW+PTW)-1:0]  pifo_data0; // {count, metadata, priority}
   reg [(CTW+MTW+PTW)-1:0]  pifo_data1;
   reg [(CTW+MTW+PTW)-1:0]  pifo_data2;
   reg [(CTW+MTW+PTW)-1:0]  pifo_data3;   

   reg [1:0]                min_sub_tree;
   reg [1:0]                min_data_port;

   reg [(MTW+PTW)-1:0]      next_push_data0;
   reg [(MTW+PTW)-1:0]      next_push_data1;
   reg [(MTW+PTW)-1:0]      next_push_data2;
   reg [(MTW+PTW)-1:0]      next_push_data3;

//-----------------------------------------------------------------------------
// Sequential Logic
//-----------------------------------------------------------------------------
   always @ (posedge i_clk or negedge i_arst_n) begin
      if (~i_arst_n) begin
         pifo_data0  <= {{CTW{1'b0}},{MTW{1'b0}},{PTW{1'b1}}};
         pifo_data1  <= {{CTW{1'b0}},{MTW{1'b0}},{PTW{1'b1}}};
         pifo_data2  <= {{CTW{1'b0}},{MTW{1'b0}},{PTW{1'b1}}};
         pifo_data3  <= {{CTW{1'b0}},{MTW{1'b0}},{PTW{1'b1}}};		 
         latch_data  <= 'b1;
      end else begin
         case ({i_push,i_pop})
         2'b00: begin
            pifo_data0   <= pifo_data0;
            pifo_data1   <= pifo_data1;
            pifo_data2   <= pifo_data2;
            pifo_data3   <= pifo_data3;		 
            latch_data   <= 'b1;				                              
            o_push[3:0]  <= 4'd0;
            o_push_data  <= 'd0;
            o_pop[3:0]   <= 4'd0;  
            o_result     <= 'd0;                  
         end
         
         2'b01: begin		
            latch_data   <= 'b1;
            o_push[3:0]  <= 4'd0;
            o_push_data  <= 'd0;
            case (min_data_port[1:0])
            2'b00: begin // pop 0                           
               pifo_data0 <= pifo_data0[PTW-1:0] == {PTW{1'b1}} ? pifo_data0 : {pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)]-1, i_pop_data[(MTW+PTW)-1:0]};           
               pifo_data1 <= pifo_data1;
               pifo_data2 <= pifo_data2;
               pifo_data3 <= pifo_data3;	                
               o_pop[3:0] <= 4'b0001;
               o_result	 <= o_pop_data;
            end

            2'b01: begin // pop 1             
               pifo_data1 <= pifo_data1[PTW-1:0] == {PTW{1'b1}} ? pifo_data1 : {pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)]-1, i_pop_data[2*(MTW+PTW)-1:(MTW+PTW)]};
               pifo_data0 <= pifo_data0;
               pifo_data2 <= pifo_data2;
               pifo_data3 <= pifo_data3;		                  
               o_pop[3:0] <= 4'b0010;
               o_result	 <= o_pop_data;	                   
            end

            2'b10: begin // pop 2             
               pifo_data2 <= pifo_data2[PTW-1:0] == {PTW{1'b1}} ? pifo_data2 : {pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)]-1, i_pop_data[3*(MTW+PTW)-1:2*(MTW+PTW)]};
               pifo_data0 <= pifo_data0;
               pifo_data1 <= pifo_data1;
               pifo_data3 <= pifo_data3;		       
               o_pop[3:0] <= 4'b0100;  
               o_result	  <= o_pop_data;    
            end

            2'b11: begin // pop 3             
               pifo_data3 <= pifo_data3[PTW-1:0] == {PTW{1'b1}} ? pifo_data3 : {pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)]-1, i_pop_data[4*(MTW+PTW)-1:3*(MTW+PTW)]};		 						
               pifo_data0 <= pifo_data0;
               pifo_data1 <= pifo_data1;
               pifo_data2 <= pifo_data2;         
               o_pop[3:0] <= 4'b1000;
               o_result   <= o_pop_data;           
            end				
            endcase
         end
            
         2'b10: begin
            latch_data =  i_push_data;
            o_pop[3:0] =  4'd0;
            o_result   <= 'd0;
            
            case (min_sub_tree[1:0])
            2'b00: begin // push 0
               pifo_data0 <= {pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)]+1, next_push_data0};
               pifo_data1 <= {pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data1};
               pifo_data2 <= {pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data2};
               pifo_data3 <= {pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data3};		
                  
               if (pifo_data0[(PTW)-1:0] != {(PTW){1'b1}}) begin
                  o_push[3:0]     = 4'b0001;
                  o_push_data     = (latch_data[(PTW)-1:0] < pifo_data0[(PTW)-1:0]) ? pifo_data0[(MTW+PTW)-1:0] : latch_data;
               end else begin
                  o_push[3:0]     = 4'b0000;
                  o_push_data     = 'd0;
               end				              
            end

            2'b01: begin // push 1
               pifo_data0 <= {pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data0};
               pifo_data1 <= {pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)]+1, next_push_data1};
               pifo_data2 <= {pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data2};
               pifo_data3 <= {pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data3};	     

               if (pifo_data1[(PTW)-1:0] != {(PTW){1'b1}}) begin
                  o_push[3:0]     = 4'b0010;
                  o_push_data      = (latch_data[(PTW)-1:0] < pifo_data1[(PTW)-1:0]) ? pifo_data1[(MTW+PTW)-1:0] : latch_data;
               end else begin
                  o_push[3:0]     = 4'b0000;
                  o_push_data     = 'd0;
               end			 					
            end

            2'b10: begin // push 2
               pifo_data0 <= {pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data0};
               pifo_data1 <= {pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data1};
               pifo_data2 <= {pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)]+1, next_push_data2};
               pifo_data3 <= {pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data3};	    	 

               if (pifo_data2[(PTW)-1:0] != {(PTW){1'b1}}) begin
                  o_push[3:0]     = 4'b0100;
                  o_push_data     = (latch_data[(PTW)-1:0] < pifo_data2[(PTW)-1:0]) ? pifo_data2[(MTW+PTW)-1:0] : latch_data;		 
               end else begin
                  o_push[3:0]     = 4'b0000;
                  o_push_data     = 'd0;
               end		               
            end

            2'b11: begin // push 3
               pifo_data0 <= {pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data0};
               pifo_data1 <= {pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data1};
               pifo_data2 <= {pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)], next_push_data2};
               pifo_data3 <= {pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)]+1, next_push_data3};		 
               
               if (pifo_data3[(PTW)-1:0] != {(PTW){1'b1}}) begin
                  o_push[3:0]     = 4'b1000;
                  o_push_data     = (latch_data[(PTW)-1:0] < pifo_data3[(PTW)-1:0]) ? pifo_data3[(MTW+PTW)-1:0] : latch_data;
               end else begin
                  o_push[3:0]     = 4'b0000;
                  o_push_data     = 'd0;
               end	     
            end

            endcase       
         end

         2'b11: begin
            pifo_data0 <= pifo_data0;
            pifo_data1 <= pifo_data1;
            pifo_data2 <= pifo_data2;
            pifo_data3 <= pifo_data3;	
            latch_data <= 'b1;
            o_result    <= 'd0;            
            o_push[3:0] = 4'd0;
            o_push_data = 'd0;
            o_pop[3:0]  = 4'd0;            
         end	

         endcase		
      end  
   end
//-----------------------------------------------------------------------------
// Combinatorial Logic / Continuous Assignments
//-----------------------------------------------------------------------------
   always @ * begin
      // Find the minimum sub-tree.
      if (pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
         pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
         pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)]) begin
         min_sub_tree[1:0] = 2'b00;	  
      end else if (pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
                  pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
                  pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)]) begin
         min_sub_tree[1:0] = 2'b01;	  
      end else if (pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data0[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
                  pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data1[(CTW+MTW+PTW)-1:(MTW+PTW)] &&
                  pifo_data2[(CTW+MTW+PTW)-1:(MTW+PTW)] <= pifo_data3[(CTW+MTW+PTW)-1:(MTW+PTW)]) begin
         min_sub_tree[1:0] = 2'b10;
      end else begin
         min_sub_tree[1:0] = 2'b11;
      end		 
      
      // Find the minimum data and minimum data port.
      if (pifo_data0[(PTW)-1:0] <= pifo_data1[(PTW)-1:0] &&
         pifo_data0[(PTW)-1:0] <= pifo_data2[(PTW)-1:0] &&
         pifo_data0[(PTW)-1:0] <= pifo_data3[(PTW)-1:0]) begin
         min_data_port[1:0]   = 2'b00;
      end else if (pifo_data1[(PTW)-1:0] <= pifo_data0[(PTW)-1:0] &&
                  pifo_data1[(PTW)-1:0] <= pifo_data2[(PTW)-1:0] &&
                  pifo_data1[(PTW)-1:0] <= pifo_data3[(PTW)-1:0]) begin
         min_data_port[1:0]   = 2'b01;
      end else if (pifo_data2[(PTW)-1:0] <= pifo_data0[(PTW)-1:0] &&
                  pifo_data2[(PTW)-1:0] <= pifo_data1[(PTW)-1:0] &&
                  pifo_data2[(PTW)-1:0] <= pifo_data3[(PTW)-1:0]) begin
         min_data_port[1:0]   = 2'b10;
      end else begin
         min_data_port[1:0]   = 2'b11;
      end		 	
      
      case (min_sub_tree[1:0])
      2'b00: begin
         next_push_data0 = (i_push_data[(PTW)-1:0] < pifo_data0[(PTW)-1:0]) ? i_push_data : pifo_data0[(MTW+PTW)-1:0];
         next_push_data1 = pifo_data1[(MTW+PTW)-1:0];
         next_push_data2 = pifo_data2[(MTW+PTW)-1:0];
         next_push_data3 = pifo_data3[(MTW+PTW)-1:0];
      end
      2'b01: begin
         next_push_data1 = (i_push_data[(PTW)-1:0] < pifo_data1[(PTW)-1:0]) ? i_push_data : pifo_data1[(MTW+PTW)-1:0];
         next_push_data0 = pifo_data0[(MTW+PTW)-1:0];
         next_push_data2 = pifo_data2[(MTW+PTW)-1:0];
         next_push_data3 = pifo_data3[(MTW+PTW)-1:0];
      end
      2'b10: begin
         next_push_data2 = (i_push_data[(PTW)-1:0] < pifo_data2[(PTW)-1:0]) ? i_push_data : pifo_data2[(MTW+PTW)-1:0];
         next_push_data1 = pifo_data1[(MTW+PTW)-1:0];
         next_push_data0 = pifo_data0[(MTW+PTW)-1:0];
         next_push_data3 = pifo_data3[(MTW+PTW)-1:0];
      end
      2'b11: begin
         next_push_data3 = (i_push_data[(PTW)-1:0] < pifo_data3[(PTW)-1:0]) ? i_push_data : pifo_data3[(MTW+PTW)-1:0];
         next_push_data1 = pifo_data1[(MTW+PTW)-1:0];
         next_push_data2 = pifo_data2[(MTW+PTW)-1:0];
         next_push_data0 = pifo_data0[(MTW+PTW)-1:0];
      end		 
      endcase	  
      
      
      case (min_data_port[1:0])
      2'b00: begin // pop 0
         o_pop_data     = pifo_data0[(MTW+PTW)-1:0];
      end
      2'b01: begin // pop 1
         o_pop_data     = pifo_data1[(MTW+PTW)-1:0];
      end
      2'b10: begin
         o_pop_data     = pifo_data2[(MTW+PTW)-1:0];
      end
      2'b11: begin
         o_pop_data     = pifo_data3[(MTW+PTW)-1:0];
      end		 
      endcase
      
   end
      
//-----------------------------------------------------------------------------
// Output Assignments
//-----------------------------------------------------------------------------


endmodule
