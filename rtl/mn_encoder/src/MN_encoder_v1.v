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


module MN_encoder_v1(clk,clk_en,rstn,valid_in,
valid_out,data_in,data_out,compressed_flag);

parameter DISPARITY_BITS = 8;
parameter HEADER_BITS = 2;
parameter WIDTH = 1920;
parameter HEIGHT = 1080;
 parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
parameter LINE_CNT_BITS = 11;// $clog2(HEIGHT);

input clk,clk_en,rstn,valid_in;
input [DISPARITY_BITS-1:0] data_in;
output reg valid_out,compressed_flag;
output reg [DISPARITY_BITS + 1:0] data_out;
reg valid_outNxt,compressed_flagNxt;
reg [DISPARITY_BITS + 1:0] data_outNxt;
reg [DISPARITY_BITS-1:0] left_n,left_nNxt,data_in_1d,data_in_1dNxt,data_in_2d,data_in_2dNxt,data_in_3dNxt,data_in_3d;
reg we,valid_1d,valid_1dNxt,valid_2d,valid_2dNxt,valid_3d,valid_3dNxt;
reg [COLUMN_CNT_BITS-1:0] adr,adrNxt;//adr_DP,adr_DPNxt;
reg    second_line_detect,second_line_detectNxt;
wire [DISPARITY_BITS-1:0] buffer_out,data_in_valid;
reg [DISPARITY_BITS-1:0] top_right_n,top_right_nNxt,top_n,top_nNxt;
reg temp_flag,temp_flagNxt,d1_flag,d2_flag,d1_flagNxt,d2_flagNxt;
reg  [DISPARITY_BITS + 1:0] temp_out,temp_outNxt;
//raminfr_DP encoder_buffer (.clk(clk), .we(we),  .a(adr),.dpra(adr_DP), .di(data_in), .spo(top_n),.dpo(top_right_n));
single_port_RAM #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) encoder_buffer(.clk(clk),.we(we),.rst(~rstn),.a(adr),.di(data_in),.do(buffer_out));
assign data_in_valid = second_line_detect ? data_in_3d : data_in;
always @(posedge clk) begin

    if(clk_en) begin
        valid_out <= valid_outNxt;
        compressed_flag <= compressed_flagNxt;
        data_out <= data_outNxt;
        left_n <= left_nNxt;
        data_in_1d <= data_in_1dNxt;
        data_in_2d <= data_in_2dNxt;
        data_in_3d <= data_in_3dNxt;
        d1_flag <= d1_flagNxt;
        d2_flag <= d2_flagNxt;

     //   top_n <= top_nNxt;
     //   top_right_n <= top_right_nNxt;
        second_line_detect <= second_line_detectNxt;
        valid_1d <= valid_1dNxt;
        valid_2d <= valid_2dNxt;
        valid_3d <= valid_3dNxt;
        adr <= adrNxt;
     //   adr_DP <= adr_DPNxt;
        temp_flag <= temp_flagNxt;
        temp_out <= temp_outNxt; 
        top_right_n <= top_right_nNxt;
        top_n <= top_nNxt; 
    end
end

always @(*) begin
    data_outNxt = data_out;
    data_in_1dNxt = data_in;
    data_in_2dNxt = data_in_1d;
    data_in_3dNxt =  data_in_2d;
    temp_outNxt = temp_out;
    temp_flagNxt = 0;
   
    left_nNxt = left_n;

    valid_outNxt = 0;
    compressed_flagNxt = 0;
    we = 0;
    valid_1dNxt =  valid_out;
    valid_2dNxt = valid_1d;
    valid_3dNxt = valid_2d;
    adrNxt = adr;
    top_right_nNxt = buffer_out;
    top_nNxt = top_right_n;
 //   adr_DPNxt = adr_DP;
    d1_flagNxt = 0;
    d2_flagNxt = d1_flag;
    
    if(!valid_in) valid_1dNxt = 0; 
    
    second_line_detectNxt = second_line_detect;
    if(!rstn || ((!valid_in) && (!valid_3d))) begin
        data_outNxt = 0;

        valid_outNxt = 0;
        compressed_flagNxt = 0; 
        second_line_detectNxt = 0;
        adrNxt =0;
   //     adr_DPNxt = 0;  
    end


    else if(valid_in ||  (valid_3d )) begin
        if(d1_flag == 1 || d2_flag == 1) valid_outNxt = 0;
        else valid_outNxt = 1;
        
       
        adrNxt = adr + 1;
   //     adr_DPNxt = adr + 2;
        we = 1;       
        if(adr == (WIDTH -1)) begin
             adrNxt = 0;
             second_line_detectNxt = 1;
             
           //  adr_DPNxt = 1;
             if(second_line_detect == 0) begin
                  valid_outNxt = 0;
                  d1_flagNxt = 1;
                 
             end     
            
        end     

        if(!second_line_detect) begin
           
            left_nNxt = data_in_valid;
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
            left_nNxt = data_in_valid;
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
