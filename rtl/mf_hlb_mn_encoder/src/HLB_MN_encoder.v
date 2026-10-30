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


module HLB_MN_encoder(clk,clk_en,rstn,valid_in,
valid_out,data_in,data_out,compressed_flag,column_cnt_r,line_cnt_r);

parameter DISPARITY_BITS = 8;
parameter HEADER_BITS = 2;
parameter WIDTH = 1920;
parameter BRAM_WIDTH = WIDTH/2;
parameter HEIGHT = 1080;
 parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
parameter LINE_CNT_BITS = 11;// $clog2(HEIGHT);
input [LINE_CNT_BITS-1:0]   line_cnt_r;
input clk,clk_en,rstn,valid_in;
input [COLUMN_CNT_BITS-1:0] column_cnt_r;
input [DISPARITY_BITS-1:0] data_in;
output reg valid_out,compressed_flag;
output reg [DISPARITY_BITS + 1:0] data_out;
reg valid_outNxt,compressed_flagNxt;
reg [DISPARITY_BITS + 1:0] data_outNxt;
reg [DISPARITY_BITS-1:0] left_n,left_nNxt,data_in_1d,data_in_1dNxt,data_in_2d,data_in_2dNxt,data_in_3dNxt,data_in_3d;
reg [DISPARITY_BITS-1:0]data_in_4d,data_in_4dNxt,data_in_5d,data_in_5dNxt; 
reg we,valid_1d,valid_1dNxt,valid_2d,valid_2dNxt,valid_3d,valid_3dNxt;
reg [COLUMN_CNT_BITS-1:0] adr,adrNxt,prev_adr,prev_adrNxt;//adr_DP,adr_DPNxt;
reg    second_line_detect,second_line_detectNxt;
wire [DISPARITY_BITS-1:0] buffer_out,data_in_valid;
reg [DISPARITY_BITS-1:0] top_right_n,top_right_nNxt,top_n,top_nNxt,top_n_1dNxt,top_n_1d;
reg temp_flag,temp_flagNxt,d1_flag,d2_flag,d1_flagNxt,d2_flagNxt;
reg  [DISPARITY_BITS + 1:0] temp_out,temp_outNxt;
reg we_r,we_rNxt;
reg adr_flag,adr_flagNxt;
reg [COLUMN_CNT_BITS-1:0] column_cnt_encoder,column_cnt_encoderNxt;
//raminfr_DP encoder_buffer (.clk(clk), .we(we),  .a(adr),.dpra(adr_DP), .di(data_in), .spo(top_n),.dpo(top_right_n));
HLB #(.WIDTH(BRAM_WIDTH)) encoder_buffer(.clk(clk),.we(we),.rst(~rstn),.a(adr[COLUMN_CNT_BITS-2:0]),.di(data_in),.do(buffer_out));
assign data_in_valid = second_line_detect ? data_in_3d : data_in_1d;
always @(posedge clk) begin

    if(clk_en) begin
        valid_out <= valid_outNxt;
        compressed_flag <= compressed_flagNxt;
        data_out <= data_outNxt;
        left_n <= left_nNxt;
        data_in_1d <= data_in_1dNxt;
        data_in_2d <= data_in_2dNxt;
        data_in_3d <= data_in_3dNxt;
        data_in_4d <= data_in_4dNxt;
        data_in_5d <= data_in_5dNxt;
        d1_flag <= d1_flagNxt;
        d2_flag <= d2_flagNxt;
        column_cnt_encoder <= column_cnt_encoderNxt;

     //   top_n <= top_nNxt;
     //   top_right_n <= top_right_nNxt;
        second_line_detect <= second_line_detectNxt;
        valid_1d <= valid_1dNxt;
        valid_2d <= valid_2dNxt;
        valid_3d <= valid_3dNxt;
        prev_adr <= prev_adrNxt;
        adr <= adrNxt;
     //   adr_DP <= adr_DPNxt;
        temp_flag <= temp_flagNxt;
        temp_out <= temp_outNxt; 
        top_right_n <= top_right_nNxt;
        top_n_1d <= top_n_1dNxt;
        top_n <= top_nNxt; 
        we_r <= we_rNxt;
        adr_flag <= adr_flagNxt;
    end
end

always @(*) begin
    data_outNxt = data_out;
    data_in_1dNxt = data_in;
    data_in_2dNxt = data_in_1d;
    data_in_3dNxt =  data_in_2d;
    data_in_4dNxt = data_in_3d;
    data_in_5dNxt = data_in_4d;
    temp_outNxt = temp_out;
    temp_flagNxt = 0;
    we_rNxt = we;
    adr_flagNxt = 0;
   
    column_cnt_encoderNxt = column_cnt_encoder;
    left_nNxt = left_n;

    valid_outNxt = 0;
    compressed_flagNxt = 0;
    we = 0;
    valid_1dNxt =  valid_out;
    valid_2dNxt = valid_1d;
    valid_3dNxt = valid_2d;
    adrNxt = adr;
    prev_adrNxt = adr;
    top_right_nNxt = buffer_out;
    top_n_1dNxt = top_right_n;
   if(we_r) top_nNxt =  top_n;
   else  top_nNxt =  top_n_1d;
    
    d1_flagNxt = 0;
    d2_flagNxt = d1_flag;
    
    if(!valid_in) valid_1dNxt = 0; 
    
    second_line_detectNxt = second_line_detect;
    if(!rstn || ((!valid_in) && (!valid_3d))) begin
        data_outNxt = 0;
        column_cnt_encoderNxt = 0;
        valid_outNxt = 0;
        compressed_flagNxt = 0; 
        second_line_detectNxt = 0;
        adrNxt =0;
        
   //     adr_DPNxt = 0;  
    end
    if(column_cnt_r == 6 && line_cnt_r == 3) begin
          we = 1;
          adrNxt = adr + 1;          
    end

    else if(valid_in ||  (valid_3d )) begin
        if(column_cnt_encoder == WIDTH - 1) column_cnt_encoderNxt = 0;
        else column_cnt_encoderNxt = column_cnt_encoder + 1;
        if((d1_flag == 1 || d2_flag == 1) && adr != 0) valid_outNxt = 0;
        else valid_outNxt = 1;
        if(prev_adr == (BRAM_WIDTH-1) && second_line_detect )adrNxt = 0;
        else if(prev_adr == 0) begin
            adrNxt = 1;
            //adr_flagNxt = 1;
            
        end
        else if (column_cnt_encoder%2!= 0)adrNxt = adr + 1;           
        if(column_cnt_encoder%2== 0 ) we = 0;
             
        else  we = 1;
          
        if(adr == (BRAM_WIDTH -1)) begin
           
             second_line_detectNxt = 1;
             
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
            else data_outNxt = {data_in_valid,2'b00};       
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
        
            else if( (data_in_valid == top_right_n) && (column_cnt_encoder != 0) && (column_cnt_encoder != 1)) begin
                compressed_flagNxt = 1;
                data_outNxt = {top_right_n,2'b11};                          
            end
            else data_outNxt = {data_in_valid,2'b00};                
             
        end
    
     
    end 


end
endmodule
