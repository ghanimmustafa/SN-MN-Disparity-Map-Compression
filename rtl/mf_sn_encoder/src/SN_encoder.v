`timescale 1ns / 1ps


// The core module of Type-1 encoding algorithm
// Its inputs are given by the top-module and image processor module
module SN_encoder(clk,clk_en,rstn,valid_in,valid_out,data_in,data_out,compressed_flag_r
    );
	 
	 parameter DISPARITY_BITS = 8;


	 
	 input clk,clk_en,rstn,valid_in;
	 input [DISPARITY_BITS-1:0] data_in;
	 output reg [DISPARITY_BITS:0] data_out ;
	 reg [DISPARITY_BITS:0] data_outNxt;

	 output reg valid_out;
	 reg valid_outNxt;
	 // compressed flag is set HIGH when the current disparity is equal to its left neighbour 
	 output reg compressed_flag_r;
	 reg compressed_flagNxt_r;
	 reg [DISPARITY_BITS-1:0] left_neighbour, left_neighbourNxt;
	 always@(posedge clk ) begin

			if(clk_en) begin
				data_out <=  data_outNxt;
				left_neighbour <= left_neighbourNxt;
				valid_out <= valid_outNxt;
				compressed_flag_r <=  compressed_flagNxt_r;
			end
 
	end	
	 always @(*) begin
	     left_neighbourNxt = left_neighbour;
	     data_outNxt = data_out;
	     valid_outNxt = 0;
         compressed_flagNxt_r = 0;
		 if(rstn == 0) begin
			data_outNxt = 0;
			left_neighbourNxt = 0;
			valid_outNxt = 0;
			compressed_flagNxt_r = 0;
		 end
		else if (valid_in) begin
            left_neighbourNxt = data_in;
            valid_outNxt = 1;			 	
            if(data_in == left_neighbour) begin
            // In order to avoid dynamic power loss due to frequent toggling, we keep
            // the previous data when we can compress the current data.     
                data_outNxt = {data_in,1'b1}; 
                compressed_flagNxt_r = 1;
            end
 
            else data_outNxt = {data_in,1'b0}; 
		end
			
    end
endmodule   



       
    

 

