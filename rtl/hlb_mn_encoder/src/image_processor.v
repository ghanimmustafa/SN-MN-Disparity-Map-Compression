`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2021 12:29:56 AM
// Design Name: 
// Module Name: image_processor
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


module image_processor(clk,clk_en,rstn,vsynch_in,hsynch_in,data_enable_in, vsynch_out,hsynch_out,data_in,valid_out
, column_cnt_r,line_cnt_r,data_out);
	 
	 parameter DISPARITY_BITS = 8;
	 parameter WIDTH = 1920;
	 parameter HEIGHT = 1080;
     parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 11;// $clog2(HEIGHT);

	 input clk,clk_en,rstn, vsynch_in,hsynch_in, data_enable_in;
	 input [DISPARITY_BITS-1:0] data_in;
	 output reg vsynch_out, hsynch_out;
	 output reg valid_out;
	 output reg [DISPARITY_BITS -1:0] data_out;
	 reg [DISPARITY_BITS -1:0] data_outNxt;
	 reg valid_outNxt_r;

	 // LINE means ROW 
	 reg  hsynch_outNxt_r, vsynch_outNxt_r;
	output reg [LINE_CNT_BITS-1:0] line_cnt_r;
	 reg [LINE_CNT_BITS-1:0] line_cntNxt_r;
	 output reg [COLUMN_CNT_BITS-1:0] column_cnt_r;
	 reg [COLUMN_CNT_BITS-1:0]  column_cntNxt_r;


	 
     // These are the median filter's window inputs


	 

	 always@(posedge clk ) begin

			if(clk_en) begin
				vsynch_out <= vsynch_outNxt_r;
				hsynch_out <= hsynch_outNxt_r;
				line_cnt_r <= line_cntNxt_r;
				column_cnt_r <= column_cntNxt_r;
				valid_out <= valid_outNxt_r;
				data_out <= data_outNxt;


								                      
			end

		 
	end	
	 always @(*) begin
			vsynch_outNxt_r = 0;
			hsynch_outNxt_r = hsynch_in;
			valid_outNxt_r = 0;
			line_cntNxt_r = line_cnt_r;
			column_cntNxt_r = column_cnt_r;
			data_outNxt = data_out;

			
         
		 if((rstn == 0) ) begin
			vsynch_outNxt_r = 0;
			hsynch_outNxt_r = 0;
			line_cntNxt_r = 1;
			column_cntNxt_r = 0;
			valid_outNxt_r = 0;
			data_outNxt = 0;

			
			
		 end
		 else begin
		    // we process the data when the ENABLE signal is HIGH, however, we have to turn off the ENABLE
		    // when no more inputs are left in the frame and we still processing the last line of the frame.
		    // Thus, such a condition is required.   				
			if( (data_enable_in) || ( line_cnt_r == HEIGHT) ) begin

                data_outNxt = data_in;
                valid_outNxt_r = 1;
                column_cntNxt_r = column_cnt_r + 1;
                
                if((column_cnt_r == (WIDTH - 1 ))) begin
                     column_cntNxt_r = 0;
                     line_cntNxt_r = line_cnt_r + 1;
                     if(line_cnt_r == HEIGHT) begin
                         line_cntNxt_r = 1;
                         vsynch_outNxt_r = 1;
                     end    
                     
                end     			  
                
			end
   
	 
	 end
end	 

endmodule   
