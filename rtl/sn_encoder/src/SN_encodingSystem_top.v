`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:09:41 06/15/2020 
// Design Name: 
// Module Name:    top 
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

// Top-Module of Encoding System: It connects all the required submodules
module SN_encodingSystem_top(clk,clk_en,rstn,vsynch_in,hsynch_in,data_enable_in,
    data_in,valid_encoded,valid_word,compressed_flag_r,overflow_flag,memory_word,encoded_data,last_packet
    , column_cnt_r,vsynch_out,hsynch_out,update_frame);
    
     parameter DISPARITY_BITS = 8;
	parameter WIDTH = 1920;
	parameter HEIGHT = 1080;
	 parameter MEMORY_WORD_BITS = 128;
     parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 11;//$clog2(HEIGHT);

     
     input   clk,clk_en,rstn,vsynch_in,hsynch_in,data_enable_in;
     input [DISPARITY_BITS -1 :0] data_in;
     output  valid_encoded,compressed_flag_r;
     output overflow_flag;
     output  [MEMORY_WORD_BITS - 1 :0] memory_word;
     output [DISPARITY_BITS :0] encoded_data;
     output valid_word;
     output last_packet;
     output  [COLUMN_CNT_BITS:0] column_cnt_r;     
     output vsynch_out, hsynch_out;
     output update_frame;

     wire vsynch_out, hsynch_out;
     wire [DISPARITY_BITS -1 :0]  processed_data;
     wire valid_filtered;
	 wire [LINE_CNT_BITS:0] line_cnt_r;

	 

     
    image_processor #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) image_processor_i(.clk(clk),.clk_en(clk_en),.rstn(rstn),
     .valid_out(valid_filtered),.data_enable_in(data_enable_in),.vsynch_in(vsynch_in),
    .hsynch_in(hsynch_in),.data_in(data_in),.data_out(processed_data),.vsynch_out(vsynch_out),.hsynch_out(hsynch_out),
   .column_cnt_r(column_cnt_r),.line_cnt_r(line_cnt_r));  

          
    SN_encoder SN_encoder_i(.clk(clk),.clk_en(clk_en),.rstn(rstn),.valid_in(valid_filtered),
     .valid_out(valid_encoded),.compressed_flag_r(compressed_flag_r),
    .data_in(processed_data),.data_out(encoded_data));
    

       SN_packetizer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) SN_packetizer_i (.clk(clk),.clk_en(clk_en),
      .valid_data(valid_encoded),.compressed_flag_r(compressed_flag_r),
    .valid_memory_word(memory_word),.overflow_flag(overflow_flag),
    .valid_word(valid_word),.encoded_data(encoded_data),.rstn(rstn),.vsynch_in(vsynch_out),.last_packet(last_packet)
   ,.data_enable_in(data_enable_in),.update_frame(update_frame));
    



     
endmodule


