`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:09:09 09/01/2020 
// Design Name: 
// Module Name:    median_filter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sorter(a,b,c,min,max,med);

// This is a small module for median filter that calculates the min, max , and median value of three inputs
parameter DISPARITY_BITS = 8;

input [DISPARITY_BITS-1:0] a,b,c;
output reg [DISPARITY_BITS-1:0] min,max,med;
reg [DISPARITY_BITS-1:0] tmp_a,tmp_b,tmp_c; 


always @(*) begin

	
	 if ((a <= b) && (b <= c) && ( a <= c)) begin
		med =  b;
		min = a;
        max = c;		// a b c
	 end		
  else  if ((a <= c) && (c <= b) && ( a <= b)) begin
		med = c;
		min = a;
		max = b;
	    // a c b
		
	 end	
  else  if ((b <= a) && (a <= c) && ( b <= c)) begin
	  med = a;
	  max = c;
	  min = b;
		  // b a c
	 end	
  else  if ((b <= c) && (c <= a) && ( b <= a ) ) begin
	  med = c;
	  max = a;
	  min = b;		
	 // b c a
	 end
  else  if ((c <= a) && (a <= b) && ( c <= b)) begin
	  med = a;
	  max = b;
	  min = c;
	 end  // c a b
	else begin 
	  med = b;
	  max = a;
	  min = c;									// c b a
	end
end
endmodule 

module median_filter(clk,rstn,in0,in1,in2,in3,in4,in5,in6,in7,in8,out
    );
// This median filter is based on nine element sorting network, explained in:
// https://inst.eecs.berkeley.edu/~cs250/fa12/handouts/lab2-median-filter.pdf
	 
parameter DISPARITY_BITS = 8;
input clk,rstn;
input [DISPARITY_BITS -1:0] in0,in1,in2,in3,in4,in5,in6,in7,in8;
reg [DISPARITY_BITS -1:0] in0_r,in1_r,in2_r,in3_r,in4_r,in5_r,in6_r,in7_r,in8_r;
reg [DISPARITY_BITS -1:0] in0_rNxt,in1_rNxt,in2_rNxt,in3_rNxt,in4_rNxt,in5_rNxt,in6_rNxt,in7_rNxt,in8_rNxt;

output reg [DISPARITY_BITS -1:0] 	 out;
reg [DISPARITY_BITS -1:0] outNxt;
wire [DISPARITY_BITS -1:0] median;
wire [DISPARITY_BITS -1 : 0] min_1,med_1,max_1, min_2,med_2,max_2,  min_3,med_3,max_3,  min_4, med_5,max_6;

sorter sorter_1(.a(in0_r),.b(in1_r),.c(in2_r),.min(min_1),.med(med_1),.max(max_1));
sorter sorter_2(.a(in3_r),.b(in4_r),.c(in5_r),.min(min_2),.med(med_2),.max(max_2));
sorter sorter_3(.a(in6_r),.b(in7_r),.c(in8_r),.min(min_3),.med(med_3),.max(max_3));
sorter sorter_4(.a(max_1),.b(max_2),.c(max_3),.min(min_4));
sorter sorter_5(.a(med_1),.b(med_2),.c(med_3),.med(med_5));
sorter sorter_6(.a(min_1),.b(min_2),.c(min_3),.max(max_6));
sorter sorter_7(.a(min_4),.b(med_5),.c(max_6),.med(median));

always @(posedge clk) begin
     out <= outNxt;
     in0_r <= in0_rNxt;
     in1_r <= in1_rNxt;
     in2_r <= in2_rNxt;
     in3_r <= in3_rNxt;
     in4_r <= in4_rNxt;
     in5_r <= in5_rNxt;
     in6_r <= in6_rNxt;
     in7_r <= in7_rNxt;                         
     in8_r <= in8_rNxt;                         
          
     
end     
     
always @(*) begin
    if(!rstn) begin
         outNxt = 0;
        in0_rNxt = 0;
        in1_rNxt = 0;
        in2_rNxt = 0;
        in3_rNxt = 0;
        in4_rNxt = 0;
        in5_rNxt = 0;
        in6_rNxt = 0;
        in7_rNxt = 0;                         
        in8_rNxt = 0;         
    end     
    else begin
        outNxt = median;
        in0_rNxt = in0;
        in1_rNxt =  in1;
        in2_rNxt = in2;
        in3_rNxt =  in3;
        in4_rNxt = in4;
        in5_rNxt = in5;
        in6_rNxt = in6;
        in7_rNxt = in7;                         
        in8_rNxt =  in8; 
   end 
end


endmodule 