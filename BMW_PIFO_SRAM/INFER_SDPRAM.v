`timescale 1ns/1ns
//-----------------------------------------------------------------------------
// Crestron Electronics
// Proprietary and Confidential Information
//
//
// Module: INFER_SDPRAM
// Author: Michael Bottiglieri...Mostly a template from Quartus
// Date  : 6/13/16
//
// Description:
//             Quartus Prime Verilog Template
//             Simple Dual Port RAM with separate read/write addresses and
//             Single read/write clock
//
// Notes:
//
//-----------------------------------------------------------------------------
// Module Port Definition
//-----------------------------------------------------------------------------


module INFER_SDPRAM #( parameter DATA_WIDTH = 32, 
                       parameter ADDR_WIDTH = 5, 
                       parameter ARCH       = 0, 
                       parameter RDW_MODE   = 0,
                       parameter INIT_VALUE = 'd0  )
(
 input                    i_clk,       //Clock
 input                    i_arst_n,    //Active Low Async Reset
                                       // Note: Usage depends on parameter
                                       //       settings
 input                    i_we,        //Active High Write Enable
 input [(ADDR_WIDTH-1):0] i_waddr,     //Write  Address
 input [(DATA_WIDTH-1):0] i_wdata,     //Write  Data

 input                    i_re,        //Active High Read Enable.
                                       
 input [(ADDR_WIDTH-1):0] i_raddr,     //Read   Address

 output reg [(DATA_WIDTH-1):0] o_rdata //Read Data (1 Clock latency)
);

reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0] /* synthesis ramstyle = "MLAB" */;

integer i;
initial begin
   for (i=0;i<2**ADDR_WIDTH;i=i+1) begin
      ram[i] = INIT_VALUE;
   end
end

//-----------------------------------------------------------------------------
//     Usage Notes
//-----------------------------------------------------------------------------
//ARCH 
// 0 =  M20K
// 1 =  MLAB

//RDW_MODE 
// 0 =  Old Data on Read/Write of Same address if ARCH = M20K
//      else Indeterminate when ARCH = MLAB.
// 1 =  New Data on Mixed Port Read/WRitre of Same address

//-----------------------------------------------------------------------------
//     RAM Storage Behavioral Sequential Logic
//-----------------------------------------------------------------------------

 generate

  //---------------------------------------------------------------------------
  // MLAB with Mix Port RDW = New Data
  // Not supported natively in MLAB, so create pass-thru logic to mimic
  // behavior. Quartus Fitter doesn't know this is occurring, so doesn't
  // report anything under Mixed Port RDW Column

  if ((ARCH == 1) && (RDW_MODE == 1))
   begin

//   reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0] /* synthesis ramstyle = "MLAB" */;

   reg [DATA_WIDTH-1:0] wdata_q;
   reg rdw_simul;
   reg [DATA_WIDTH-1:0] ram_rdata;

    always @ (posedge i_clk)
     begin
      if (i_we) 
       ram[i_waddr] <= i_wdata;

      wdata_q   <= i_wdata;
      rdw_simul <= (i_raddr == i_waddr) & i_we;

      if (i_re) 
       ram_rdata <= ram[i_raddr];

     end
   
    always @ (*)
     begin
      o_rdata      = rdw_simul ? wdata_q : ram_rdata;
     end

   end

  //---------------------------------------------------------------------------
  // MLAB with Mix Port RDW = Indeterminate--Unclear if Meta-Stable or
  // or just "random" if simulatenous R/W to same location.

  if ((ARCH == 1) && (RDW_MODE == 0))
   begin

//    reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0] /* synthesis ramstyle = "MLAB" */;
    always @ (posedge i_clk)
     begin
      if (i_we) ram[i_waddr] <= i_wdata; 
      if (i_re) o_rdata      <= ram[i_raddr];
     end

   end

  //---------------------------------------------------------------------------
  //M20K w/ New Data on Mixed Port RDW
  //
  //Note: The M20K block does not natively support New Data across ports.
  //Altera adds Pass-Thru Logic to handle this behavior (slows access down,
  //adds gates). Unlike with MLABs, the coding style below is detected by
  //Quartus (as described in theoir Synthesis Handbook) and the Pass-Through
  //logic is inferred. The Quartus Analysis-Synthesis report file will
  //have a message that the Pass-Through Logic was added, but the Fitter
  //RAM Summary does not actually report anything under "Mixed-Port" RDW
  //Must be a Left-hand/Right-hand thing!

  if ((ARCH == 0) && (RDW_MODE == 1))
   begin

//   reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0] /* synthesis ramstyle = "M20K" */;

    always @ (posedge i_clk)
     begin
      if (i_we) 
          ram[i_waddr] = i_wdata;       //Blocking
      if (i_re) 
          o_rdata      = ram[i_raddr];  //Blocking
     end

   end

  //---------------------------------------------------------------------------
  //M20K w/ Old Data on Mixed Port RDW
  //
  //The M20K block natively supports this.
  //The Fitter RAM Summary will reflect this in the "Mixed-Port" RDW column

  if ((ARCH == 0) && (RDW_MODE == 0))
   begin


//    reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0] /* synthesis ramstyle = "M20K" */;

    always @ (posedge i_clk)
     begin
      if (i_we) ram[i_waddr] <= i_wdata;
      if (i_re) o_rdata      <= ram[i_raddr];
     end

   end

  endgenerate

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// For Simulation Only
//-----------------------------------------------------------------------------

`ifdef SIM_INFER_RAM_VERBOSE

  initial
    begin
      $display("\n");
      $display("INFO : INFER_SDPRAM Instance %m Parameters -> ADDR_WIDTH %d : DATA_WIDTH %d : ARCH %d i.e. target %s : RDW_MODE %d i.e. %s ", ADDR_WIDTH,DATA_WIDTH, ARCH , ARCH ? "MLAB" : "M20K", RDW_MODE, RDW_MODE ? "New Data on Simul RW same addr" : "Old Data on Simul RW same addr");
      $display("\n");
   end
`endif
  


endmodule
