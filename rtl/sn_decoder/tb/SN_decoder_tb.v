`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2020 01:58:16 AM
// Design Name: 
// Module Name: decoder_tb
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

// Testbench used for Type-1 Decoding System
// Mustafa Ghanim

module SN_decoder_tb;

    parameter CLOCK_PERIOD = 20;
    parameter HALF_CLOCK_PERIOD = CLOCK_PERIOD/2;
    parameter DISPARITY_BITS = 8;
    parameter WIDTH = 1920;
    parameter HEIGHT = 1078;
	parameter TOTAL_PIXELS = HEIGHT * WIDTH;
	// You need to manually find the number of memory words in the packets text file for finalization operation.
	parameter TOTAL_MEMORY_WORDS = 309488; 
	parameter COLUMN_CNT_BITS = $clog2(WIDTH);
	parameter MAX_STRING_CHARACTERS = 80;

	parameter MEMORY_WORD_BITS = 128;
    reg [8 * MAX_STRING_CHARACTERS:0] packets_file_name = "hw_sn_packets.txt";
    reg [8 * MAX_STRING_CHARACTERS:0] decoded_file_name = "hw_sn_decoded.txt";



	// Inputs
	reg clk;
	reg clk_en;
	reg rstn;
	reg [MEMORY_WORD_BITS - 1:0] memory_word;
	reg valid_in;
	integer i,mw_counter,valid_cnt;
	integer decoded_image_file;
	 
	// Outputs

    wire valid_dec;
    wire [DISPARITY_BITS-1:0] decoder_out;
    wire packet_decoded,  hsynch_dec , vsynch_dec;     
	// Instantiate the Unit Under Test (UUT)
	SN_decoder #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) uut (
		.clk(clk), 
		.clk_en(clk_en), 
		.rstn(rstn), 
		.valid_in(valid_in),


		.memory_word(memory_word), 

		.hsynch_dec(hsynch_dec),
		.vsynch_dec(vsynch_dec),
		.decoder_out(decoder_out),
		.valid_dec(valid_dec),
		.packet_decoded(packet_decoded)		
	);
	
	    // Read Binary File
	 reg [MEMORY_WORD_BITS - 1:0] input_memory_words[TOTAL_MEMORY_WORDS - 1:0];
	 initial begin
	 if ($value$plusargs("PACKETS_FILE=%s", packets_file_name)) begin end
	 if ($value$plusargs("DECODED_FILE=%s", decoded_file_name)) begin end
	 $readmemb(packets_file_name,input_memory_words);
	 end
	 initial begin
	 
		// Initialize Inputs
		clk = 0;
		clk_en = 1;
		rstn = 0;
		mw_counter = 0;
		valid_in = 0;
	    decoded_image_file = $fopen(decoded_file_name,"w");
        valid_cnt = 0;

		#90;
		rstn = 1;
	    clk_en = 1;
	    memory_word = input_memory_words[0];
	    valid_in = 0;
	    mw_counter = 1;
	    #CLOCK_PERIOD;
	 // Since the exact time of finishing decoding operation depends on the input memory words, a for loop with 
	 // huge length is set to stay safe only. It will finish before that of course:) 
	 for ( i = 0; i < (TOTAL_PIXELS * 2); i = i +1) begin
	    if(i == 0) valid_in = 1;
	    else  valid_in = 0;
	    if(packet_decoded) begin
	       memory_word = input_memory_words[mw_counter];
	       mw_counter = mw_counter + 1;
	       valid_in = 1;
	       
	    end
	    if(valid_dec) begin
	        $fdisplay(decoded_image_file,"%h",decoder_out);
	    end    
	    if(vsynch_dec) begin
	       #CLOCK_PERIOD;
	       $fclose(decoded_image_file);
	       $finish;
	    
	    end 
	   
	 
	 
	 
	   #CLOCK_PERIOD;
	 
	 end
	 
	 
	 
	 
	 
	 end

	always 
	#HALF_CLOCK_PERIOD 
	clk = ~ clk;

   
endmodule

