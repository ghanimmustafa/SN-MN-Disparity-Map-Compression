`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2021 12:43:22 AM
// Design Name: 
// Module Name: median_filter
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


module sorter(a,b,c,min,max,med);

// This is a small module for median filter that calculates the min, max , and median value of three inputs
parameter DISPARITY_BITS = 8;

input [DISPARITY_BITS-1:0] a,b,c;
output reg [DISPARITY_BITS-1:0] min,max,med;
reg [DISPARITY_BITS-1:0] tmp_a,tmp_b,tmp_c; 

// comp1, comp2, comp3;

assign comp1 = (a <= b);
assign comp2 = (b <= c);
assign comp3 = ( a <= c);

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

module median_filter(clk,in0,in1,in2,in3,in4,in5,in6,in7,in8,out
    );
// This median filter is based on nine element sorting network, explained in:
// https://inst.eecs.berkeley.edu/~cs250/fa12/handouts/lab2-median-filter.pdf
	 
parameter DISPARITY_BITS = 8;
input clk;
input [DISPARITY_BITS -1:0] in0,in1,in2,in3,in4,in5,in6,in7,in8;
output reg [DISPARITY_BITS -1:0] out;
reg [DISPARITY_BITS -1:0] outNxt;
wire [DISPARITY_BITS -1:0] in0_w,in1_w,in2_w;
//reg [DISPARITY_BITS -1:0] in0_r,in1_r,in2_r,in3_r,in4_r,in5_r,in6_r,in7_r,in8_r;
//reg [DISPARITY_BITS -1:0] in0_rNxt,in1_rNxt,in2_rNxt,in3_rNxt,in4_rNxt,in5_rNxt,in6_rNxt,in7_rNxt,in8_rNxt;
reg [9*DISPARITY_BITS - 1:0] filter_shift_reg,filter_shift_regNxt;
wire [DISPARITY_BITS -1:0] median;
wire [DISPARITY_BITS -1 : 0] min_1,med_1,max_1, min_2,med_2,max_2,  min_3,med_3,max_3,  max_4;
reg [DISPARITY_BITS -1 : 0] min_1d,min_1dNxt,min_1dd,min_1ddNxt,med_1d,med_1dNxt,med_1dd,med_1ddNxt;
reg [DISPARITY_BITS -1 : 0] max_1d,max_1dNxt,max_1dd,max_1ddNxt;
assign {in0_w,in1_w,in2_w} = filter_shift_reg[DISPARITY_BITS*3 -1:0];

sorter sorter_1(.a(in0_w),.b(in1_w),.c(in2_w),.min(min_1),.med(med_1),.max(max_1));
sorter sorter_2(.a(max_1),.b(max_1d),.c(max_1dd),.min(min_2));
sorter sorter_3(.a(med_1),.b(med_1d),.c(med_1dd),.med(med_3));
sorter sorter_4(.a(min_1),.b(min_1d),.c(min_1dd),.max(max_4));
sorter sorter_5(.a(min_2),.b(med_3),.c(max_4),.med(median));
//sorter sorter_6(.a(min_1),.b(min_2),.c(min_3),.max(max_6));
//sorter sorter_7(.a(min_4),.b(med_5),.c(max_6),.med(median));

always @(posedge clk) begin
     out <= outNxt;
     filter_shift_reg <= filter_shift_regNxt;
     max_1d <= max_1dNxt;
     max_1dd <= max_1ddNxt;
     med_1d <= med_1dNxt;
     med_1dd <= med_1ddNxt;                              
     min_1d <= min_1dNxt;
     min_1dd <= min_1ddNxt;            
     
end     
 /*
 .in0(w33),.in1(w32),.
     in2(w31),.in3(w23),.in4(w22)
     ,.in5(w21),.in6(w13),.in7(w12),.in8(w11)
 */    
always @(*) begin

        outNxt = median;
        filter_shift_regNxt = filter_shift_reg >> (DISPARITY_BITS)*3;
        filter_shift_regNxt = {in0,in3,in6,in1,in4,in7,in2,in5,in8};
        max_1dNxt = max_1;
        max_1ddNxt = max_1d;      
        med_1dNxt = med_1;
        med_1ddNxt = med_1d;    
        min_1dNxt = min_1;
        min_1ddNxt = min_1d;     

end


endmodule 