`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2021 10:57:14 AM
// Design Name: 
// Module Name: encoder_type2
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


module MN_encoder(clk,clk_en,rstn,valid_in,
valid_out,data_in,data_out,compressed_flag);

parameter DISPARITY_BITS = 8;
parameter HEADER_BITS = 2;
	parameter WIDTH = 2874;
	parameter HEIGHT = 1982;
     parameter COLUMN_CNT_BITS = 14;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 13;//$clog2(HEIGHT);


input clk,clk_en,rstn,valid_in;
input [DISPARITY_BITS-1:0] data_in;
output reg valid_out,compressed_flag;
output reg [DISPARITY_BITS + 1:0] data_out;
reg valid_outNxt,compressed_flagNxt;
reg [DISPARITY_BITS + 1:0] data_outNxt;
reg [DISPARITY_BITS-1:0] left_n,left_nNxt,data_in_1d,data_in_1dNxt,data_in_2d,data_in_2dNxt;
reg we,valid_d,valid_dNxt;
reg [COLUMN_CNT_BITS:0] adr,adrNxt,adr_DP,adr_DPNxt;
reg    second_line_detect,second_line_detectNxt;
wire [DISPARITY_BITS-1:0] top_n,top_right_n,data_in_valid;
reg temp_flag,temp_flagNxt;
reg  [DISPARITY_BITS + 1:0] temp_out,temp_outNxt;
encoder_buffer encoder_buffer_i (.clk(clk), .we(we),  .a(adr),.dpra(adr_DP), .di(data_in), .spo(top_n),.dpo(top_right_n));
assign data_in_valid = second_line_detect ? data_in_1d : data_in;
always @(posedge clk) begin

    if(clk_en) begin
        valid_out <= valid_outNxt;
        compressed_flag <= compressed_flagNxt;
        data_out <= data_outNxt;
        left_n <= left_nNxt;
        data_in_1d <= data_in_1dNxt;
        data_in_2d <= data_in_2dNxt;
     //   top_n <= top_nNxt;
     //   top_right_n <= top_right_nNxt;
        second_line_detect <= second_line_detectNxt;
        valid_d <= valid_dNxt;
        adr <= adrNxt;
        adr_DP <= adr_DPNxt;
        temp_flag <= temp_flagNxt;
        temp_out <= temp_outNxt;  
    end
end

always @(*) begin
    data_outNxt = data_out;
    data_in_1dNxt = data_in;
    data_in_2dNxt = data_in_1d;
    temp_outNxt = temp_out;
    temp_flagNxt = 0;
   
    left_nNxt = left_n;

    valid_outNxt = 0;
    compressed_flagNxt = 0;
    we = 0;
    valid_dNxt =  valid_out;
    adrNxt = adr;
    adr_DPNxt = adr_DP;
    if(!valid_in) valid_dNxt = 0; 
    
    second_line_detectNxt = second_line_detect;
    if(!rstn || ((!valid_in) && (!valid_d))) begin
        data_outNxt = 0;

        valid_outNxt = 0;
        compressed_flagNxt = 0; 
        second_line_detectNxt = 0;
        adrNxt =0;
        adr_DPNxt = 0;  
    end


    else if(valid_in ||  (valid_d )) begin
        
        valid_outNxt = 1;
       
        adrNxt = adr + 1;
        adr_DPNxt = adr + 2;
        we = 1;       
        if(adr == (WIDTH -1)) begin
             adrNxt = 0;
             second_line_detectNxt = 1;
             adr_DPNxt = 1;
             if(second_line_detect == 0)  valid_outNxt = 0;
            
        end     

        if(!second_line_detect) begin
           
            left_nNxt = data_in;
            if(data_in_valid == left_n) begin
                if(adr == (WIDTH -1)) begin
                     temp_flagNxt = 1;
                     temp_outNxt = {left_n,2'b01};
                     compressed_flagNxt = temp_flag;
                     data_outNxt =  temp_out;
                end
                else begin     
                    compressed_flagNxt = 1;
                    data_outNxt = {left_n,2'b01}; 
                end    
            end
            else data_outNxt = {data_in,2'b00};       
        end
        
        else begin
          //    left_nNxt = data_in_1d;  
            left_nNxt = data_in_1d;
            if(data_in_valid == left_n) begin

                if(((adr == 0) && (!valid_out) && (!temp_flag))) begin
                    compressed_flagNxt = 0;

                    data_outNxt = {data_in_valid,2'b00};
               end
                else begin
                    compressed_flagNxt = 1;
                    data_outNxt = {left_n,2'b01};                   
               end 
            end
            else if( data_in_valid == top_n) begin
                compressed_flagNxt = 1;
                data_outNxt = {top_n,2'b10};                          
            end    
        
            else if( data_in_valid == top_right_n) begin
                compressed_flagNxt = 1;
                data_outNxt = {top_right_n,2'b11};                          
            end
            else data_outNxt = {data_in_valid,2'b00};                
             
        end
    
     
    end 


end
endmodule
