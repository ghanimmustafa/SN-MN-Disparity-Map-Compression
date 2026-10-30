`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2020 02:46:59 AM
// Design Name: 
// Module Name: decoder
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


module SN_decoder(clk,clk_en,rstn,memory_word,packet_decoded,hsynch_dec,
vsynch_dec,decoder_out,valid_in,valid_dec

    );
    parameter MEMORY_WORD_BITS = 128;
    parameter DISPARITY_BITS = 8;
    parameter WIDTH = 1920;
    parameter HEIGHT = 1078;
    // Notice that we clip the orginal unfiltered frame's height by 2 due to median filter operation

    parameter LINE_CNT_BITS = 13;//$clog2(HEIGHT);
    parameter COLUMN_CNT_BITS = 14;//$clog2(WIDTH); 
    // Index bits for the index counter through one memory word decoding
    parameter INDEX_BITS = 10;//$clog2(MEMORY_WORD_BITS);
    // Remaining bits for decoding the end and begining of a memory word ( optimization condition)
    parameter REMAINING_BITS = 4;//$clog2(DISPARITY_BITS);         
    input clk,clk_en,rstn,valid_in;
    output reg hsynch_dec,vsynch_dec,valid_dec;
    // packet_decoded indicates that the decoder is ready to receive a new memory word from the testbench 
    output reg packet_decoded;
    output reg [DISPARITY_BITS - 1:0] decoder_out;
    input [ MEMORY_WORD_BITS - 1:0] memory_word;
    reg hsynch_decNxt,vsynch_decNxt,packet_decodedNxt,valid_decNxt;
    reg [DISPARITY_BITS - 1:0] decoder_outNxt;
    reg [MEMORY_WORD_BITS-1:0] memory_word_buffer,memory_word_bufferNxt;
    reg [LINE_CNT_BITS:0] line_cnt_dec,line_cnt_decNxt;
    reg [COLUMN_CNT_BITS:0] column_cnt_dec,column_cnt_decNxt;
    reg [2:0] decoder_state,decoder_stateNxt,prev_state,prev_stateNxt;
    reg [INDEX_BITS:0] mw_index,mw_indexNxt,prev_index,prev_indexNxt;
    wire [INDEX_BITS:0] remaning_bits;
    assign remaning_bits = MEMORY_WORD_BITS -  mw_index -1;
    // remaning_bits_r is responsible for the MSB remaining bits, i.e remaining bits at the new memory word
    // remaning_bits is responsible for the LSB remaining bits, i.e remaining bits at the current memory word
    reg [REMAINING_BITS-1:0] remaning_bits_r,remaning_bits_rNxt; 
    reg [DISPARITY_BITS-1:0] LSB_part,MSB_part,LSB_partNxt,MSB_partNxt;
    reg flag,flagNxt;
   // output reg update_frame;
  //  reg update_frameNxt;
    // flag: is used to apply a condition which was not considered in the main state machine of the decoder
    // it is the condition when we have the header bit of uncompressed disparity at the last index (127) of 
    // the current memory word.
    always@(posedge clk) begin
        if(clk_en) begin
            decoder_out <= decoder_outNxt;
           memory_word_buffer <= memory_word_bufferNxt;
            packet_decoded <= packet_decodedNxt;
            hsynch_dec <= hsynch_decNxt;
            vsynch_dec <= vsynch_decNxt;
            line_cnt_dec <= line_cnt_decNxt;
            column_cnt_dec <= column_cnt_decNxt;
            decoder_state <= decoder_stateNxt;
            mw_index <= mw_indexNxt;
            remaning_bits_r <= remaning_bits_rNxt;
            LSB_part <= LSB_partNxt;
            MSB_part <= MSB_partNxt;

            flag <= flagNxt;

            prev_index <= prev_indexNxt;
            valid_dec <= valid_decNxt;
       //     update_frame <= update_frameNxt;

        end
        
    end
    
    
   always @(*) begin
        prev_stateNxt = decoder_state;
        prev_indexNxt = mw_index;
        valid_decNxt = 0;
      //  update_frameNxt = 0;
      //  if(vsynch_dec) update_frameNxt = 1;
        
        if((!rstn) || ( vsynch_dec) ) begin
           decoder_outNxt = 0;
          memory_word_bufferNxt = 0;
           packet_decodedNxt = 0;
           hsynch_decNxt = 0;
           vsynch_decNxt = 0;
           line_cnt_decNxt = 1;
           column_cnt_decNxt = 0;
           decoder_stateNxt = 0;
           mw_indexNxt = 0;
           remaning_bits_rNxt = 0;
           MSB_partNxt = 0;
           LSB_partNxt = 0;
           flagNxt = 0;


                  
        end
        
        else begin


            decoder_outNxt = decoder_out;
            memory_word_bufferNxt = memory_word_buffer;
            packet_decodedNxt = 0;
            hsynch_decNxt = 0;
            vsynch_decNxt = 0;
            line_cnt_decNxt =  line_cnt_dec;
            column_cnt_decNxt = column_cnt_dec;
            mw_indexNxt = mw_index;
            remaning_bits_rNxt = remaning_bits_r;
            decoder_stateNxt = decoder_state;


             MSB_partNxt = MSB_part;

             LSB_partNxt =  LSB_part;
           
             
            flagNxt = flag;
            case(decoder_state)
                0: begin  
                    // the is the starting point of decoder state matchine                
                    if(valid_in) begin
                         memory_word_bufferNxt = memory_word;
                         decoder_stateNxt = 1; 
                    end
                end
                 
                1: begin
                        LSB_partNxt = 0;
                        MSB_partNxt = 0;
                        if(prev_state == 3) flagNxt = 0;                          
                        if( (mw_index == (MEMORY_WORD_BITS - 1) )) begin
                        
                            mw_indexNxt = 0;
                            decoder_stateNxt = 0;
                            packet_decodedNxt = 1;
                            if((memory_word_buffer[mw_index] == 0))flagNxt = 1;
                            
                            else begin
                                
                                 valid_decNxt = 1;
                                 decoder_outNxt = decoder_out;
                                 // update column and row counters
                                 if( column_cnt_dec == ( WIDTH -1)) begin
                                    if(line_cnt_dec == HEIGHT) begin
                                        vsynch_decNxt = 1;
                                        line_cnt_decNxt = 1;
                                    end
                                    else line_cnt_decNxt = line_cnt_dec +  1 ;
                                    column_cnt_decNxt = 0;
                                    hsynch_decNxt = 1;       
                                 end
                                 else column_cnt_decNxt = column_cnt_dec + 1;                               
                                 flagNxt = 0;                            
                                                           
                            end 
                                                                            
                        end

                        // Uncompressed data case and remaining bits are large enough.
                        else if((memory_word_buffer[mw_index] == 0) && ( remaning_bits >= DISPARITY_BITS)) begin
                           
                           if(flag) begin
                             decoder_outNxt = {memory_word_buffer[mw_index + 7],
                                            memory_word_buffer[mw_index + 6],
                                            memory_word_buffer[mw_index + 5],
                                            memory_word_buffer[mw_index + 4],
                                            memory_word_buffer[mw_index + 3],
                                            memory_word_buffer[mw_index + 2],
                                            memory_word_buffer[mw_index + 1],
                                            memory_word_buffer[mw_index ]}; 
                            mw_indexNxt =  mw_index + DISPARITY_BITS ;
                            flagNxt = 0;                                            
                           
                           end 
                           else begin 
                                decoder_outNxt = {memory_word_buffer[mw_index + DISPARITY_BITS],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 1],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 2],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 3],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 4],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 5],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 6],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 7]};
                                if( remaning_bits == DISPARITY_BITS) begin
                                     mw_indexNxt = 0;
                                     decoder_stateNxt = 0;
                                     packet_decodedNxt = 1;
                                end                    
                                else mw_indexNxt =  mw_index + DISPARITY_BITS + 1;                
                            end                
                            valid_decNxt = 1;
                            // update column and row counters
                             if( column_cnt_dec == ( WIDTH -1)) begin
                                    if(line_cnt_dec == HEIGHT) begin
                                        vsynch_decNxt = 1;
                                        line_cnt_decNxt = 1;
                                    end
                                    else line_cnt_decNxt = line_cnt_dec +  1 ;
                                column_cnt_decNxt = 0;
                                hsynch_decNxt = 1;       
                             end
                             else column_cnt_decNxt = column_cnt_dec + 1;  
                        end
                        // Uncompressed data but the remaining bits are less than 9 bits
                        else if((memory_word_buffer[mw_index] == 0) && ( remaning_bits < DISPARITY_BITS) && ( remaning_bits !=0) ) begin
                            decoder_stateNxt = 2;
                            packet_decodedNxt = 1;
                            remaning_bits_rNxt = (DISPARITY_BITS ) - remaning_bits;
                            mw_indexNxt = 0;
                            // Store the required LSB part of the uncompressed data according to "remaining bits" value
                            case(remaning_bits)
                      
                                1: LSB_partNxt[0] = memory_word_buffer[mw_index + 1];
                                2: LSB_partNxt[1:0] = {memory_word_buffer[mw_index + 2], memory_word_buffer[mw_index + 1]};
                                3: LSB_partNxt[2:0] = {memory_word_buffer[mw_index + 3], memory_word_buffer[mw_index + 2],memory_word_buffer[mw_index + 1]};
                                4: LSB_partNxt[3:0] = {memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2],memory_word_buffer[mw_index + 1]};
                                5: LSB_partNxt[4:0] = {memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2],memory_word_buffer[mw_index + 1]};                             
                                6: LSB_partNxt[5:0] = {memory_word_buffer[mw_index + 6],memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2],memory_word_buffer[mw_index + 1]};                                   
                                7: LSB_partNxt[6:0] = {memory_word_buffer[mw_index + 7],memory_word_buffer[mw_index + 6],memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2],memory_word_buffer[mw_index + 1]};                                                               
                            endcase
                            
                        
                                               
                        end    
                        // Compressed Data Case
                        else if((memory_word_buffer[mw_index] == 1) && ( remaning_bits >= 1)  && (!flag)) begin
                            mw_indexNxt =  mw_index  + 1;
                            valid_decNxt = 1;
                            decoder_outNxt = decoder_out;
                             // update column and row counters
                             if( column_cnt_dec == ( WIDTH -1)) begin
                                    if(line_cnt_dec == HEIGHT) begin
                                        vsynch_decNxt = 1;
                                        line_cnt_decNxt = 1;
                                    end
                                    else line_cnt_decNxt = line_cnt_dec +  1 ;
                                column_cnt_decNxt = 0;
                                hsynch_decNxt = 1;       
                             end
                             else column_cnt_decNxt = column_cnt_dec + 1;  
                         
                        end
                        
                        else if((memory_word_buffer[mw_index] ==1) && (flag)) begin
                           

                             decoder_outNxt = {memory_word_buffer[mw_index + 7],
                                            memory_word_buffer[mw_index + 6],
                                            memory_word_buffer[mw_index + 5],
                                            memory_word_buffer[mw_index + 4],
                                            memory_word_buffer[mw_index + 3],
                                            memory_word_buffer[mw_index + 2],
                                            memory_word_buffer[mw_index + 1],
                                            memory_word_buffer[mw_index ]}; 
                            mw_indexNxt =  mw_index + DISPARITY_BITS ;
                            flagNxt = 0;
                             // update column and row counters
                            if( column_cnt_dec == ( WIDTH -1)) begin
                                    if(line_cnt_dec == HEIGHT) begin
                                        vsynch_decNxt = 1;
                                        line_cnt_decNxt = 1;
                                    end
                                    else line_cnt_decNxt = line_cnt_dec +  1 ;
                                column_cnt_decNxt = 0;
                                hsynch_decNxt = 1;       
                             end
                             else column_cnt_decNxt = column_cnt_dec + 1; 
                             valid_decNxt = 1;                            
                                                                        
                           
                          end    
                        
                                        
                    end
                
                2: begin
                        // This is an empty state used for synchronization purpose
                        // i.e. to recieve the correct memory word at the exact clock cycle
                        decoder_stateNxt = 3;        
                      
                end
                3:begin
                        // Update the memory buffer
                        memory_word_bufferNxt = memory_word;
                        decoder_stateNxt = 4; 

                        
                
                end
                
                4: begin
                
                
                    // Now we set the value of MSB part ( for uncompressed data) according to "remaning_bits_r" value
                       case(remaning_bits_r)
                    1: MSB_partNxt[7] = memory_word_buffer[mw_index ];
                    2: MSB_partNxt[7:6] = {memory_word_buffer[mw_index + 1], memory_word_buffer[mw_index ]};
                    3: MSB_partNxt[7:5] = {memory_word_buffer[mw_index + 2], memory_word_buffer[mw_index + 1],memory_word_buffer[mw_index]};
                    4: MSB_partNxt[7:4] = {memory_word_buffer[mw_index + 3],memory_word_buffer[mw_index + 2],
                    memory_word_buffer[mw_index + 1],memory_word_buffer[mw_index ]};
                    5: MSB_partNxt[7:3] = {memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],memory_word_buffer[mw_index + 2],
                    memory_word_buffer[mw_index + 1],memory_word_buffer[mw_index ]};                             
                    6: MSB_partNxt[7:2] = {memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],memory_word_buffer[mw_index + 2],
                    memory_word_buffer[mw_index + 1],memory_word_buffer[mw_index ]};                                   
                    7: MSB_partNxt[7:1] = {memory_word_buffer[mw_index + 6],memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],memory_word_buffer[mw_index + 2],
                    memory_word_buffer[mw_index + 1],memory_word_buffer[mw_index ]};
                                                
                    endcase 
                    decoder_stateNxt = 5;               
                              
                
                
                
                
                end
                
                5: begin
                   // Set the index value for the first decoded disparity of the new memory word
                   
                    mw_indexNxt =  mw_index + remaning_bits_r;
                    // The final decoded data of a new memory word is equal to the 
                    // sum of LSB and MSB parts of it. MSB and LSB are organized such that
                    // no bit intersections can happen. Thus, the sum operation works fine. 
                    decoder_outNxt = MSB_part + LSB_part;
                    valid_decNxt = 1;
                    decoder_stateNxt = 1;
                    // update column and row counters
                    if( column_cnt_dec == ( WIDTH -1)) begin
                         if(line_cnt_dec == HEIGHT) begin
                            vsynch_decNxt = 1;
                            line_cnt_decNxt = 1;
                        end
                        else line_cnt_decNxt = line_cnt_dec +  1 ;
                    column_cnt_decNxt = 0;
                    hsynch_decNxt = 1;       
                    end
                    else column_cnt_decNxt = column_cnt_dec + 1;
                          
                
                
                
                end                            
                 

                
                           
            endcase
      
        
        end
     
    end
endmodule

    
    
 
