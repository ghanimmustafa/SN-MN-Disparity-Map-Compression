`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2020 10:13:39 PM
// Design Name: 
// Module Name: encoding_sys_tb_lineBuffers_embedded
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
`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////

// This is the main testbench used for Type-1 Encoding System

module SN_MF_encodingSys_tb;
    parameter CLOCK_PERIOD = 8;
    parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2;
    parameter DISPARITY_BITS = 8;
    parameter WIDTH =  1920;
    parameter HEIGHT = 1080;
	parameter TOTAL_PIXELS = HEIGHT * WIDTH;
	parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
	parameter MAX_STRING_CHARACTERS = 80; 

	parameter MEMORY_WORD_BITS = 128;
    reg [8 * MAX_STRING_CHARACTERS:0] input_image_name_1 = "input_disparity_map.txt";
    // output binary files to be written
    reg [8 * MAX_STRING_CHARACTERS:0] packets_file_name_1 = "hw_mf_sn_packets.txt";
	// Inputs
	reg clk;
	reg clk_en;
	reg rstn;
	reg vsynch_in;
	reg hsynch_in;
	reg data_enable_in;
	reg [DISPARITY_BITS - 1:0] data_in;

	// Outputs

	wire [DISPARITY_BITS:0] encoded_data;
	wire valid_encoded;
	wire valid_word;
    wire compressed_flag_r;
    wire  overflow_flag;
    wire [MEMORY_WORD_BITS -1:0] memory_word;
    wire last_packet;
    wire [COLUMN_CNT_BITS-1:0] column_cnt_r;
    wire hsynch_out,vsynch_out;
  
	// Instantiate the Unit Under Test (UUT)
	SN_encoding_system_top #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) uut (
		.clk(clk), 
		.clk_en(clk_en), 
		.rstn(rstn), 
		.vsynch_in(vsynch_in), 
		.hsynch_in(hsynch_in), 
		.data_enable_in(data_enable_in), 

		.data_in(data_in), 
		.encoded_data(encoded_data),
		.valid_encoded(valid_encoded),
		.compressed_flag_r(compressed_flag_r),
		.overflow_flag(overflow_flag),
		.memory_word(memory_word),
		.valid_word(valid_word),
		.last_packet(last_packet),

		.column_cnt_r(column_cnt_r),
		.hsynch_out(hsynch_out),
		.vsynch_out(vsynch_out)

		
	);
    // Read Hex File ( unfiltered disparity image in raster scan order)
	 reg [DISPARITY_BITS - 1:0] input_pixels_1[TOTAL_PIXELS - 1:0];
//	 reg [DISPARITY_BITS - 1:0] input_pixels_2[TOTAL_PIXELS - 1:0];
	 initial begin
	 if ($value$plusargs("INPUT_FILE=%s", input_image_name_1)) begin end
	 if ($value$plusargs("PACKETS_FILE=%s", packets_file_name_1)) begin end
	 $readmemh(input_image_name_1,input_pixels_1);
	 end
//	 initial begin
//	 $readmemh(input_image_name_2,input_pixels_2);
//	 end
	 integer i;
	 integer memory_words_file;
	 integer encoded_data_file;

	initial begin
		// Initialize Inputs
		clk = 0;
		clk_en = 1;
		rstn = 0;
		vsynch_in = 0;
		hsynch_in = 0;
		data_enable_in = 0;

		#90;
		rstn = 1;
		clk_en = 1;
		data_enable_in = 1;
	
	  
	
	    memory_words_file = $fopen(packets_file_name_1,"w");
//	    encoded_data_file = $fopen(encoded_file_name,"w");
        // Due to buffering operation we need to wait for few clock cycles for one frame to be completly packetized 
        // before moving to the next frame. Applying the rstn signal LOW and HIGH again is the easiest way
        // to verify the testbench successfully for multiple frames. 
		for ( i = 0; i <= (TOTAL_PIXELS + 8) ; i = i + 1)
		begin
		      data_in = input_pixels_1[i];
						  			
			if(((i > 0) && ( valid_word == 1))) $fdisplay(memory_words_file,"%b",memory_word); 
		//	if( (i > 0) && (valid_encoded == 1)) $fdisplay(encoded_data_file,"%b",encoded_data); 
			if( (column_cnt_r  == (WIDTH - 1 )) && ( i > 0)) hsynch_in = 1;
			else hsynch_in = 0;
			if ( i == (TOTAL_PIXELS - 1))   vsynch_in = 1;
			else vsynch_in = 0;
			if ( i == TOTAL_PIXELS) data_enable_in = 0;

			#CLOCK_PERIOD;
			
		end
	//	$fclose(encoded_data_file);
		$fclose(memory_words_file);
	/*	#CLOCK_PERIOD;
		#CLOCK_PERIOD;	
		data_enable_in = 1;
	    memory_words_file = $fopen(packets_file_name_2,"w");
//	    encoded_data_file = $fopen(encoded_file_name,"w");
        // Due to buffering operation we need to wait for few clock cycles for one frame to be completly packetized 
        // before moving to the next frame. Applying the rstn signal LOW and HIGH again is the easiest way
        // to verify the testbench successfully for multiple frames. 
		for ( i = 0; i <= (TOTAL_PIXELS + 8) ; i = i + 1)
		begin
		      data_in = input_pixels_2[i];
						  			
			if(((i > 0) && ( valid_word == 1))) $fdisplay(memory_words_file,"%b",memory_word); 
		//	if( (i > 0) && (valid_encoded == 1)) $fdisplay(encoded_data_file,"%b",encoded_data); 
			if( (column_cnt_r  == (WIDTH - 1 )) && ( i > 0)) hsynch_in = 1;
			else hsynch_in = 0;
			if ( i == (TOTAL_PIXELS - 1))   vsynch_in = 1;
			else vsynch_in = 0;
			if ( i == TOTAL_PIXELS) data_enable_in = 0;

			#CLOCK_PERIOD;
			
		end
	//	$fclose(encoded_data_file);
		$fclose(memory_words_file);	*/
		
		$finish;

	end
	always 
	#HALF_CLOCK_PERIOD 
	clk = ~ clk;
      
endmodule





