`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2021 02:54:51 PM
// Design Name: 
// Module Name: packetizer_type2
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


module MN_packetizer_v0(clk,clk_en,rstn,valid_data,
encoded_data,compressed_flag_r,
valid_memory_word,overflow_flag,valid_word,
 vsynch_in,last_packet,update_frame

    );


parameter WIDTH = 2874;
parameter HEIGHT = 1982;

    parameter DISPARITY_BITS = 8;
    parameter MEMORY_WORD_BITS = 128;
    parameter SHIFTS_BITS = 10;//$clog2(MEMORY_WORD_BITS);
     parameter COLUMN_CNT_BITS = 14;//$clog2(WIDTH);
	 parameter LINE_CNT_BITS = 13;//$clog2(HEIGHT);
    
  //  input [LINE_CNT_BITS:0] line_cnt_r;
    input clk,clk_en,rstn,compressed_flag_r,valid_data;
    input [DISPARITY_BITS+1:0] encoded_data;
    output reg last_packet;
    output reg  overflow_flag;
    output reg valid_word;
    output reg   [MEMORY_WORD_BITS - 1:0] valid_memory_word;
    input vsynch_in;
    reg [MEMORY_WORD_BITS - 1:0] memory_word;

    reg overflow_flagNxt;
    reg [MEMORY_WORD_BITS - 1:0] memory_wordNxt;
    reg [MEMORY_WORD_BITS - 1:0] valid_memory_wordNxt;
    reg [MEMORY_WORD_BITS - 1:0] temp_mw,temp_mwNxt;    
    reg [SHIFTS_BITS :0] shifts_cnt,shifts_cntNxt;
    wire [MEMORY_WORD_BITS - 1:0] temp_mw_w;
    assign temp_mw_w = memory_word;
    reg valid_wordNxt;
  
    reg last_packetNxt;
    reg vsynch_in_r,vsynch_in_rNxt,vsynch_in_1d,vsynch_in_1dNxt;
   wire [DISPARITY_BITS:0]  line_end_shifts;
   reg optimized_case,optimized_caseNxt;
   reg write_new_mw,write_new_mwNxt;
   reg [3:0] temp_cnt,temp_cntNxt;
   output reg update_frame;
   reg update_frameNxt;
   reg MSB_header,MSB_headerNxt;
   reg header_value,header_valueNxt;
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
            MSB_header <= MSB_headerNxt;
            header_value <= header_valueNxt;
            vsynch_in_1d <= vsynch_in_1dNxt;

        end

    end
    
  always @(*) begin
        update_frameNxt = 0;
        MSB_headerNxt = 0;
        header_valueNxt =  header_value;
        memory_wordNxt = memory_word;
        valid_memory_wordNxt = 0;
        valid_wordNxt = 0;
        shifts_cntNxt = shifts_cnt;
        write_new_mwNxt = 0;
        optimized_caseNxt = 0;
       
        overflow_flag = 0;
        temp_cntNxt = temp_cnt;
        temp_mwNxt = 0;
        last_packetNxt = 0;
        vsynch_in_rNxt = vsynch_in_r;
        vsynch_in_1dNxt = vsynch_in_r;
        
        
        if( rstn == 0)  begin
  
            shifts_cntNxt = 0;
            memory_wordNxt = 0;    
            vsynch_in_rNxt = 0;
            temp_cntNxt = 0;
            header_valueNxt = 0;       
        end
                vsynch_in_rNxt =  vsynch_in;

                
        if(vsynch_in_1d)last_packetNxt = 1;
        
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
        
        
        else if(valid_data) begin


                if(MSB_header) begin
                     valid_memory_wordNxt = memory_word;
                     valid_wordNxt = 1;
                     if(compressed_flag_r) begin
                        memory_wordNxt = valid_memory_word >> 3;
                        memory_wordNxt[MEMORY_WORD_BITS-1:MEMORY_WORD_BITS-3] = {encoded_data[1:0],header_value};
                        shifts_cntNxt = 3;
                     end
                     else begin
                        memory_wordNxt = valid_memory_word >> 3;
                        memory_wordNxt[MEMORY_WORD_BITS-1:MEMORY_WORD_BITS-DISPARITY_BITS - 3] = {encoded_data,header_value};                     
                        shifts_cntNxt = DISPARITY_BITS + 3;               
                     end   
                end
                if( optimized_case) begin
                    valid_wordNxt = 1;
                    valid_memory_wordNxt = memory_word; 
                    temp_mwNxt = temp_mw;
                    if( compressed_flag_r == 0) begin
                        
                        memory_wordNxt = temp_mw >> (DISPARITY_BITS + 2 );
                        memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS -  DISPARITY_BITS -2] = encoded_data;
                        shifts_cntNxt = DISPARITY_BITS + 2 +  temp_cnt;
                        
                                       
                    end
                    else if( compressed_flag_r == 1) begin
                        memory_wordNxt = temp_mw >> 2;
                        memory_wordNxt[MEMORY_WORD_BITS-1:MEMORY_WORD_BITS-2] = encoded_data[1:0];
                        shifts_cntNxt = 2 + temp_cnt;
                    
                    
                    end

                
                end 
               
          
                if(optimized_case == 0) begin
                    if( (compressed_flag_r == 1 ) &&  ( line_end_shifts  >= 2)) begin
                                    // When compressed, shift only by two locations
                                
                                    memory_wordNxt = memory_word >> 2;
                                    memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - 2] = encoded_data[1:0];
                                    shifts_cntNxt = shifts_cnt + 2;
                                

                    end 
                   
                    else if( (compressed_flag_r  == 0 ) &&  ( line_end_shifts  >= (DISPARITY_BITS + 2 ))) begin
                            // When uncompressed, and enough bits are available, shift by 10 bits and include the total data   
                            memory_wordNxt = memory_word >> (DISPARITY_BITS + 2);
                            memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS -  DISPARITY_BITS -2] = encoded_data;
                            shifts_cntNxt = shifts_cnt + DISPARITY_BITS + 2;
                       
    

                    end
                    
                    else begin
                    
                        // Else: An overflow case occurs
                                          
                       
                        overflow_flag = 1; 
                        if( (compressed_flag_r == 1 )  && (line_end_shifts == 0) ) begin
                        
                            // If overflow and current data is compressed, just add '1' to new memory word
                                     
                            valid_memory_wordNxt = memory_word; 
                            memory_wordNxt =  valid_memory_word >> 2;
                            memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - 2] = encoded_data[1:0];
                            shifts_cntNxt =  2;
                            valid_wordNxt = 1;

                        end
                        if( (compressed_flag_r == 1 )  && (line_end_shifts == 1) ) begin
                        
                            // If overflow and current data is compressed, just add '1' to new memory word
                                     
                            memory_wordNxt =   memory_word >> 1;
                            memory_wordNxt[MEMORY_WORD_BITS - 1] = encoded_data[0];
                            header_valueNxt = encoded_data[1];
                          //  shifts_cntNxt =  2;
                            MSB_headerNxt = 1;

                        end                        
                       
                        else if( (compressed_flag_r  == 0 ) && (line_end_shifts == 0) ) begin
                            // If overflow occurs and current data is uncompressed and no remaining bits are available;
                            // again just include the total data into new memory word.  
                            valid_memory_wordNxt = memory_word; 
                            memory_wordNxt =  valid_memory_word >> (DISPARITY_BITS + 2);
                           memory_wordNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS -  DISPARITY_BITS -2] = encoded_data;
                            shifts_cntNxt = DISPARITY_BITS + 2;
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
                             temp_cntNxt =  (DISPARITY_BITS + 2)  - line_end_shifts;
                             write_new_mwNxt = 1;
    
                            case(line_end_shifts)
                            1: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1] = encoded_data[0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS -1 ] = encoded_data[DISPARITY_BITS+1:1] ;

                            end   
                            
                            2: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 2] = encoded_data[1:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS ] = encoded_data[DISPARITY_BITS+1:2] ;

                            end                            
                            
                            3: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 3] = encoded_data[2:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 1] = encoded_data[DISPARITY_BITS+1:3] ;

                            end                          
                            
                            4: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 4] = encoded_data[3:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 2] = encoded_data[DISPARITY_BITS+1:4] ;

                            end  
                            
                            5: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 5] = encoded_data[4:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 3] = encoded_data[DISPARITY_BITS+1:5] ;

                          
                            end  
                            
                            6: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 6] = encoded_data[5:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 4] = encoded_data[DISPARITY_BITS+1:6] ;

                          
                            end  
                            
                            
                             7: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 7] = encoded_data[6:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - DISPARITY_BITS + 5] = encoded_data[DISPARITY_BITS+1:7] ;

                            end
     
                            8: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 8] = encoded_data[7:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1:MEMORY_WORD_BITS - 2] = encoded_data[DISPARITY_BITS+1:8] ;

                            end                          
 
                             9: begin
                                memory_wordNxt[MEMORY_WORD_BITS - 1: MEMORY_WORD_BITS - 9] = encoded_data[8:0];
                                temp_mwNxt[MEMORY_WORD_BITS - 1] = encoded_data[DISPARITY_BITS+1] ;

                            end                                                                                                     
                            endcase                      
                        end
                   end 
                                          
                     
                end
             end   
           end
            
                                                                         
endmodule 

