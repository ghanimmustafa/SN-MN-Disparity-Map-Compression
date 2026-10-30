`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2021 12:26:50 AM
// Design Name: 
// Module Name: encoding_system_type2
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


// Top-Module of Encoding System: It connects all the required submodules
module MN_encoding_system_top_v1(clk,clk_en,rstn,vsynch_in,hsynch_in,data_enable_in,
    data_in,valid_encoded,valid_word,compressed_flag_r,overflow_flag,valid_memory_word,encoded_data,last_packet
    , column_cnt_r,vsynch_out,hsynch_out,update_frame,line_cnt_r);
    
     parameter DISPARITY_BITS = 8;
	parameter WIDTH = 1920;
	parameter HEIGHT = 1080;
	 parameter MEMORY_WORD_BITS = 128;
     parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 11;// $clog2(HEIGHT);

     
     input   clk,clk_en,rstn,vsynch_in,hsynch_in,data_enable_in;
     input [DISPARITY_BITS -1 :0] data_in;
     output  valid_encoded,compressed_flag_r;
     output overflow_flag;
     output  [MEMORY_WORD_BITS - 1 :0] valid_memory_word;
     output [DISPARITY_BITS + 1 :0] encoded_data;
     output valid_word;
     output last_packet;
     output  [COLUMN_CNT_BITS-1:0] column_cnt_r;     
     output vsynch_out, hsynch_out;
     output update_frame;

     wire vsynch_out, hsynch_out;
     wire [DISPARITY_BITS -1 :0]   processed_data;
     wire valid_processed;
	 output [LINE_CNT_BITS-1:0] line_cnt_r;

	 

     
     image_processor #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) image_processor_i(.clk(clk),.clk_en(clk_en),.rstn(rstn),
     .valid_out(valid_processed),.data_enable_in(data_enable_in),.vsynch_in(vsynch_in),
    .hsynch_in(hsynch_in),.data_in(data_in),.data_out(processed_data),.vsynch_out(vsynch_out),.hsynch_out(hsynch_out),
   .column_cnt_r(column_cnt_r),.line_cnt_r(line_cnt_r));   

    MN_encoder_v1 #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) MN_encoder_v1_i(.clk(clk),.clk_en(clk_en),.rstn(rstn),.valid_in(valid_processed),
    .valid_out(valid_encoded),.data_in(processed_data),.data_out(encoded_data),.compressed_flag(compressed_flag_r));         

    MN_packetizer_v2 #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) MN_packetizer_v2_i(.clk(clk),.clk_en(clk_en),.rstn(rstn),.valid_data(valid_encoded),
.encoded_data(encoded_data),.compressed_flag_r(compressed_flag_r),
.valid_memory_word(valid_memory_word),.overflow_flag(overflow_flag),.valid_word(valid_word),
 .vsynch_in(vsynch_out),.last_packet(last_packet),.update_frame(update_frame)

    );

    



     
endmodule
