
`timescale 1ns / 1ps

// This packetizer module will use all the remaining bit locations in each memory word.
module SN_packetizer(clk,clk_en,rstn,valid_data,
encoded_data,compressed_flag_r,
valid_memory_word,overflow_flag,valid_word,
 vsynch_in,last_packet,data_enable_in,update_frame);

	parameter WIDTH = 2880;
	parameter HEIGHT = 1988;

    parameter DISPARITY_BITS = 8;
    parameter MEMORY_WORD_BITS = 128;
     parameter COLUMN_CNT_BITS = 11;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 11;//$clog2(HEIGHT);
     parameter SHIFTS_BITS =  8;//$clog2(MEMORY_WORD_BITS);
  
  //  input [LINE_CNT_BITS:0] line_cnt_r;
    input clk,clk_en,rstn,compressed_flag_r,valid_data;
    input [DISPARITY_BITS:0] encoded_data;
    output reg last_packet;
    output reg  overflow_flag;
    output reg valid_word;
    output reg   [MEMORY_WORD_BITS - 1:0] valid_memory_word;
    input vsynch_in;
    input data_enable_in;
    reg [MEMORY_WORD_BITS - 1:0] memory_word;

    reg overflow_flagNxt;
    reg [MEMORY_WORD_BITS - 1:0] memory_wordNxt;
    reg [MEMORY_WORD_BITS - 1:0] valid_memory_wordNxt;
    reg [MEMORY_WORD_BITS - 1:0] temp_mw,temp_mwNxt;    
    reg [SHIFTS_BITS-1 :0] shifts_cnt,shifts_cntNxt;
   
    reg valid_wordNxt;
  
    reg last_packetNxt;
    reg vsynch_in_r,vsynch_in_rNxt;
   wire [DISPARITY_BITS:0]  line_end_shifts;
   reg optimized_case,optimized_caseNxt;
   reg write_new_mw,write_new_mwNxt;
   reg [3:0] temp_cnt,temp_cntNxt;
   output reg update_frame;
   reg update_frameNxt;
   // last_packet: indicates that the last memory word of a frame is ready
   // write_new_mw and  optimized_case are signals set HIGH at the end of one memory word and begining of another
   //overflow_flag: is set HIGH when there are no enough bit locations for compressed/uncompressed data. 
   // temp_cnt: determines the number of bit locations required to be allocated in the next memory word
   // temp_mw: A temporary memory word register needed when additional clock cycle is consumed for distributing one uncompressed
   // disparity data into two seperated memory words. 
      
   assign line_end_shifts = MEMORY_WORD_BITS - shifts_cnt; // the remaining unshifted bit locations
        
     always@(posedge clk ) begin
    
        if(clk_en) begin
            memory_word <= memory_wordNxt;
            shifts_cnt <= shifts_cntNxt;
            valid_memory_word <= valid_memory_wordNxt;
            valid_word <= valid_wordNxt;
            last_packet <= last_packetNxt;
            vsynch_in_r <= vsynch_in_rNxt;
            optimized_case <= optimized_caseNxt;
            temp_mw <= temp_mwNxt;
            write_new_mw <= write_new_mwNxt;
            temp_cnt <= temp_cntNxt;
            update_frame <= update_frameNxt;

        end

    end
    
  always @(*) begin
        update_frameNxt = 0;
    
        if( (rstn == 0) || ((valid_data == 0) && ( data_enable_in == 1)) ) begin
            memory_wordNxt = 0;
            shifts_cntNxt = 0;
            overflow_flag = 0;
            valid_memory_wordNxt = 0;
            valid_wordNxt = 0;
            last_packetNxt = 0;
            vsynch_in_rNxt = 0;
            optimized_caseNxt = 0;
            temp_mwNxt = 0;
            write_new_mwNxt = 0;
            temp_cntNxt = 0;
            
            
        end
        else begin
                write_new_mwNxt = 0;
                optimized_caseNxt = 0;
                shifts_cntNxt = shifts_cnt;
                overflow_flag = 0;
                vsynch_in_rNxt =  vsynch_in;
                valid_memory_wordNxt = 0;
                valid_wordNxt = 0;
                last_packetNxt = 0;
                temp_mwNxt = 0;
                temp_cntNxt = temp_cnt;
                memory_wordNxt = memory_word;
                if(vsynch_in_r)last_packetNxt = 1;
                
                if(last_packet)  begin
                     // We need to shift the last valid memory word by the remaining bit locations to the right
                     // in order to keep the decoder order correctly.  
                     valid_memory_wordNxt = memory_word >> line_end_shifts;
                     valid_wordNxt = 1;
                     update_frameNxt = 1;
                end
                if(update_frame) begin
                // Newly added to process multiple frames
                    memory_wordNxt = 0;
                    shifts_cntNxt = 0;
                    overflow_flag = 0;
                    valid_memory_wordNxt = 0;
                    valid_wordNxt = 0;
                    last_packetNxt = 0;
                    vsynch_in_rNxt = 0;
                    optimized_caseNxt = 0;
                    temp_mwNxt = 0;
                    write_new_mwNxt = 0;
                    temp_cntNxt = 0;                
                               
                end
                if( optimized_case) begin
                    valid_wordNxt = 1;
                    valid_memory_wordNxt = memory_word; 
                    temp_mwNxt = temp_mw;
                    if( compressed_flag_r == 0) begin
                        
                        memory_wordNxt = temp_mw >> (DISPARITY_BITS + 1 );
                        memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS -  DISPARITY_BITS -1] = encoded_data;
                        shifts_cntNxt = DISPARITY_BITS + 1 +  temp_cnt;
                        
                                       
                    end
                    else if( compressed_flag_r == 1) begin
                        memory_wordNxt = temp_mw >> 1;
                        memory_wordNxt[MEMORY_WORD_BITS-1] = 1;
                        shifts_cntNxt = 1 + temp_cnt;
                    
                    
                    end

                
                end 
               
          
                if(optimized_case == 0) begin
                    if( (compressed_flag_r == 1 ) &&  ( line_end_shifts  >= 1)) begin
                                    // When compressed, shift only by one location
                                
                                    memory_wordNxt = memory_word >> 1;
                                    memory_wordNxt[MEMORY_WORD_BITS - 1] = 1'b1;
                                    shifts_cntNxt = shifts_cnt + 1;
                                

                    end 
                   
                    else if( (compressed_flag_r  == 0 ) &&  ( line_end_shifts  >= (DISPARITY_BITS + 1 ))) begin
                            // When uncompressed, and enough bits are available, shift by 9 bits and include the total data   
                            memory_wordNxt = memory_word >> (DISPARITY_BITS + 1);
                            memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS -  DISPARITY_BITS -1] = encoded_data;
                            shifts_cntNxt = shifts_cnt + DISPARITY_BITS + 1;
                       
    

                    end
                    
                    else begin
                    
                        // Else: An overflow case occurs
                                          
                       
                        overflow_flag = 1; 
                        if( (compressed_flag_r == 1 )) begin
                        
                            // If overflow and current data is compressed, just add '1' to new memory word         
                            valid_memory_wordNxt = memory_word; 
                            memory_wordNxt =  valid_memory_word >> 1;
                           memory_wordNxt[MEMORY_WORD_BITS - 1] = 1'b1;
                            shifts_cntNxt =  1;
                            valid_wordNxt = 1;

                        end
                       
                        else if( (compressed_flag_r  == 0 ) && (line_end_shifts == 0) ) begin
                            // If overflow occurs and current data is uncompressed and no remaining bits are available;
                            // again just include the total data into new memory word.  
                            valid_memory_wordNxt = memory_word; 
                            memory_wordNxt =  valid_memory_word >> (DISPARITY_BITS + 1);
                           memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS -  DISPARITY_BITS -1] = encoded_data;
                            shifts_cntNxt = DISPARITY_BITS + 1;
                            valid_wordNxt = 1;
                        end
                        
                        else if( (compressed_flag_r  == 0 ) && (line_end_shifts > 0) ) begin
                            // This part of the algorithm is a state matchine which;
                            // applies when the data is uncompressed and there is some space for new bits to fill
                            // in the current memory word before it is completly full. However, we need to calculate
                            // the exact remaining bit locations for the current memory word and for the next memory word
                            // starting from LSB to MSB based order. 
                            // The required allocations are written manually in the state machine to avoid
                            // Dynamic allocation errors in Verilog synthesis. 
                            
                             memory_wordNxt = memory_word >> line_end_shifts;
                             optimized_caseNxt = 1;
                             shifts_cntNxt  =  shifts_cnt + line_end_shifts;
                             temp_cntNxt =  (DISPARITY_BITS + 1)  - line_end_shifts;
                             write_new_mwNxt = 1;
    
                            case(line_end_shifts)
                            1: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1] = encoded_data[0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS ] = encoded_data[DISPARITY_BITS:1] ;

                            end   
                            
                            2: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 2] = encoded_data[1:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 1] = encoded_data[DISPARITY_BITS:2] ;

                            end                            
                            
                            3: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 3] = encoded_data[2:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 2] = encoded_data[DISPARITY_BITS:3] ;

                            end                          
                            
                            4: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 4] = encoded_data[3:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 3] = encoded_data[DISPARITY_BITS:4] ;

                            end  
                            
                            5: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 5] = encoded_data[4:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 4] = encoded_data[DISPARITY_BITS:5] ;

                          
                            end  
                            
                            6: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 6] = encoded_data[5:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 5] = encoded_data[DISPARITY_BITS:6] ;

                          
                            end  
                            
                            
                             7: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 7] = encoded_data[6:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 6] = encoded_data[DISPARITY_BITS:7] ;

                            end
     
                            8: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 8] = encoded_data[7:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1] = encoded_data[DISPARITY_BITS] ;

                            end                          
                                                                                                     
                            endcase                      
                        end
                   end 
                                          
                     
                end
            end
            end                                                              
endmodule 


