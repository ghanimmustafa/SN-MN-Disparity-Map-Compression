`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2021 04:45:26 PM
// Design Name: 
// Module Name: decoder_line_buffer
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


module MN_decoder_line_buffer(
clk, we, a, dpra, di, spo, dpo
    );
    

parameter WIDTH = 1920;
parameter HEIGHT = 1078;
parameter DISPARITY_BITS = 8;
parameter COLUMN_CNT_BITS = 13;//$clog2(WIDTH); 
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
 /*   
module decoder_line_buffer   
        (clk, we, a, dpra, di, spo, dpo); 
 
parameter WIDTH = 500;
parameter HEIGHT = 498;
parameter DISPARITY_BITS = 8;
parameter COLUMN_CNT_BITS = $clog2(WIDTH); 
input clk;   
input we;   
input  [COLUMN_CNT_BITS:0] a;   
input  [COLUMN_CNT_BITS:0] dpra;   
input  [DISPARITY_BITS-1:0] di;   
output [DISPARITY_BITS-1:0] spo;   
output [DISPARITY_BITS-1:0] dpo;   
reg    [DISPARITY_BITS-1:0] ram [WIDTH:0];   
reg    [COLUMN_CNT_BITS:0] read_a;   
reg    [COLUMN_CNT_BITS:0] read_dpra; 
 
  always @(posedge clk) begin   
    if (we)   
      ram[a] <= di;   
    read_a <= a;   
    read_dpra <= dpra;   
  end   
  assign spo = ram[read_a];   
  assign dpo = ram[read_dpra];   
endmodule 
*/