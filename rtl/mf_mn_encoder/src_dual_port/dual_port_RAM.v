`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2021 05:46:20 PM
// Design Name: 
// Module Name: raminfr_DP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dual_port_RAM   
        (clk, we, a, dpra, di, spo, dpo); 

parameter WIDTH = 2874;
parameter HEIGHT = 1982;
parameter DISPARITY_BITS = 8;
     parameter COLUMN_CNT_BITS = 14;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 13;//$clog2(HEIGHT);
input clk;   
input we;   
input  [COLUMN_CNT_BITS:0] a;   
input  [COLUMN_CNT_BITS:0] dpra;   
input  [DISPARITY_BITS - 1:0] di;   
output [DISPARITY_BITS - 1:0] spo;   
output [DISPARITY_BITS - 1:0] dpo;   
reg    [DISPARITY_BITS - 1:0] ram [WIDTH-1:0];   
reg    [DISPARITY_BITS - 1:0] spo;   
reg    [DISPARITY_BITS - 1:0] dpo; 
 
  always @(posedge clk) begin  
    if (we)   
      ram[a] <= di;   
    spo = ram[a];   
    dpo = ram[dpra];   
  end   
endmodule 