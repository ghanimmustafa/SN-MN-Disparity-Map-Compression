`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2021 12:32:07 AM
// Design Name: 
// Module Name: single_access_LB
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


// a single-port RAM with "false" synchronous read and reset on the output.

module single_port_RAM  (clk, we, rst, a, di, do); 
parameter WIDTH = 1920;
parameter HEIGHT = 1080;
parameter DISPARITY_BITS = 8;
 parameter COLUMN_CNT_BITS = 11;// $clog2(WIDTH);
 parameter LINE_CNT_BITS = 11;//$clog2(HEIGHT);
input clk;   
input we;   
input rst;  
input  [COLUMN_CNT_BITS-1:0] a;   
input  [DISPARITY_BITS - 1:0] di;   
output [DISPARITY_BITS - 1:0] do;   
reg    [DISPARITY_BITS - 1:0] ram [WIDTH -1:0];   
reg    [DISPARITY_BITS - 1:0] do; 
 
  always @(posedge clk) begin   
    if (we )   
      ram[a] <= di;   
    if (rst) begin   
      do <= 0;
    end    
    else   
      do <= ram[a];   
  end   
endmodule


