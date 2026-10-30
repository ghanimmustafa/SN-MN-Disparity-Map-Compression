`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/10/2021 04:31:34 PM
// Design Name: 
// Module Name: type2_decoder
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


module MN_decoder(clk,clk_en,
rstn,memory_word,packet_decoded,hsynch_dec,
vsynch_dec,decoder_out,valid_in,valid_dec
);

    parameter MEMORY_WORD_BITS = 128;
    parameter DISPARITY_BITS = 8;
    parameter WIDTH = 1920;
    parameter HEIGHT = 1078;
    // Notice that we clip the orginal unfiltered frame's height by 2 due to median filter operation

    parameter LINE_CNT_BITS = 12;//$clog2(HEIGHT);
    parameter COLUMN_CNT_BITS = 13;//$clog2(WIDTH); 
    // Index bits for the index counter through one memory word decoding
    parameter INDEX_BITS = 8;//$clog2(MEMORY_WORD_BITS);
    // Remaining bits for decoding the end and begining of a memory word ( optimization condition)
    parameter REMAINING_BITS = 5;//$clog2(DISPARITY_BITS);         
    input clk,clk_en,rstn,valid_in;
    output reg hsynch_dec,vsynch_dec,valid_dec;
    // packet_decoded indicates that the decoder is ready to receive a new memory word from the testbench 
    output reg packet_decoded;
    output reg [DISPARITY_BITS - 1:0] decoder_out;
    input [ MEMORY_WORD_BITS - 1:0] memory_word;
    reg hsynch_decNxt,vsynch_decNxt,packet_decodedNxt,valid_decNxt;
    reg [DISPARITY_BITS - 1:0] decoder_outNxt,decoder_out_r,decoder_out_rNxt;
    reg [MEMORY_WORD_BITS-1:0] memory_word_buffer,memory_word_bufferNxt;
    reg [LINE_CNT_BITS:0] line_cnt_dec,line_cnt_decNxt;
    reg [COLUMN_CNT_BITS:0] column_cnt_dec,column_cnt_decNxt;
    reg [3:0] decoder_state,decoder_stateNxt,prev_state,prev_stateNxt;
    reg [INDEX_BITS:0] mw_index,mw_indexNxt,prev_index,prev_indexNxt;
    wire [INDEX_BITS:0] remaning_bits;
    assign remaning_bits = MEMORY_WORD_BITS -  mw_index -1;
    // remaning_bits_r is responsible for the MSB remaining bits, i.e remaining bits at the new memory word
    // remaning_bits is responsible for the LSB remaining bits, i.e remaining bits at the current memory word
    reg [REMAINING_BITS-1:0] remaning_bits_r,remaning_bits_rNxt; 
    reg [DISPARITY_BITS-1:0] LSB_part,MSB_part,LSB_partNxt,MSB_partNxt,
    top_right_temp_1,top_right_temp_1Nxt,top_right_temp_2,top_right_temp_2Nxt,
    top_right_temp_3,top_right_temp_3Nxt, top_right_temp_4,top_right_temp_4Nxt,
    buffer_headerNxt,buffer_header,top_temp_1,top_temp_1Nxt,top_temp_2,top_temp_2Nxt ;
    reg flag,flagNxt;
    reg we;
    reg [COLUMN_CNT_BITS:0] adr_0,adr_0Nxt,adr_1,adr_1Nxt,adr_0_d,adr_0_dNxt,adr_1_d,adr_1_dNxt;
    wire [DISPARITY_BITS-1:0] top_n,top_right_n,top_w;
    wire [1:0] header_state;
    reg [1:0] header_state_r2,header_state_r2Nxt;
    reg [1:0] compression_state;
    assign header_state = {memory_word_buffer[mw_index+1],memory_word_buffer[mw_index]};
  
    reg header_flag,header_flagNxt;
    reg [1:0] header_state_r,header_state_rNxt;
    reg valid_in_r,valid_in_rNxt,valid_dec_r,valid_dec_rNxt,valid_in_rr,valid_in_rrNxt;

    wire [DISPARITY_BITS-1:0] buffer_decoder_out;
    assign buffer_decoder_out = decoder_outNxt;
    assign top_n = flag ? buffer_header : top_w;
    MN_decoder_line_buffer #(.WIDTH(WIDTH),.HEIGHT(HEIGHT)) MN_decoder_line_buffer_i(.clk(clk), .we(we), .a(adr_0), .dpra(adr_1), .di(decoder_outNxt), .spo(top_w), .dpo(top_right_n));
    reg temp_flag,temp_flagNxt;
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
            adr_0 <= adr_0Nxt;
            adr_1 <= adr_1Nxt;
            adr_1_d <= adr_1_dNxt;
            adr_0_d <= adr_0_dNxt;

            prev_index <= prev_indexNxt;
            valid_dec <= valid_decNxt;
            header_flag <= header_flagNxt;
       //     update_frame <= update_frameNxt;
            header_state_r <= header_state_rNxt;
            valid_in_r <= valid_in_rNxt;
            decoder_out_r <= decoder_out_rNxt;
            header_state_r2 <= header_state_r2Nxt;
            top_right_temp_1 <= top_right_temp_1Nxt;
            top_right_temp_2 <= top_right_temp_2Nxt;
            top_right_temp_3 <= top_right_temp_3Nxt;
            top_right_temp_4 <= top_right_temp_4Nxt;
            buffer_header <= buffer_headerNxt;
            top_temp_2 <= top_temp_2Nxt;
            top_temp_1 <= top_temp_1Nxt;
            valid_dec_r <= valid_dec_rNxt;
            prev_state <= prev_stateNxt;
            valid_in_rr <= valid_in_rrNxt;
            temp_flag <= temp_flagNxt;
        //    top_right_n <= top_right_nNxt;
        //    top_n <= top_nNxt;

        end
        
    end
    
    
   always @(*) begin
        prev_stateNxt = decoder_state;
        prev_indexNxt = mw_index;
        valid_decNxt = 0;
        adr_0Nxt = adr_0;
        adr_1Nxt = adr_1;

        we = 0;
        header_flagNxt = 0;
        header_state_rNxt = header_state_r;
        valid_in_rNxt = valid_in;
        line_cnt_decNxt =  line_cnt_dec;
        column_cnt_decNxt = column_cnt_dec; 
        decoder_out_rNxt = decoder_out;  
        header_state_r2Nxt = header_state;
        top_right_temp_1Nxt = top_right_n;
  //      if( column_cnt_dec == (WIDTH - 1)) top_right_temp_1Nxt = decoder_out;
        top_right_temp_2Nxt =  top_right_temp_1;
        top_right_temp_3Nxt = top_right_temp_2;
        top_right_temp_4Nxt = top_right_n;
        buffer_headerNxt = buffer_header;
        top_temp_1Nxt =  top_n;
        top_temp_2Nxt =  top_temp_2;
        flagNxt = 0;
        valid_dec_rNxt = valid_dec;
        valid_in_rrNxt = valid_in_r;
        temp_flagNxt = 0;
        adr_1_dNxt = adr_1;
        adr_0_dNxt = adr_0;
        if(line_cnt_dec == 1 && column_cnt_dec == 1 )  buffer_headerNxt = decoder_out;
        if( line_cnt_dec == 1 && column_cnt_dec == WIDTH - 1) flagNxt = 1;

        
        if((!rstn) || ( vsynch_dec) ) begin
           decoder_outNxt = 0;
          memory_word_bufferNxt = 0;
           packet_decodedNxt = 0;
           hsynch_decNxt = 0;
           vsynch_decNxt = 0;
           line_cnt_decNxt = 1;
           column_cnt_decNxt = 1;
           decoder_stateNxt = 0;
           mw_indexNxt = 0;
           remaning_bits_rNxt = 0;
           MSB_partNxt = 0;
           LSB_partNxt = 0;
           adr_0Nxt = 0;
           adr_1Nxt = 1;


                  
        end
        
        else begin


            decoder_outNxt = decoder_out;
            memory_word_bufferNxt = memory_word_buffer;
            packet_decodedNxt = 0;
            hsynch_decNxt = 0;
            vsynch_decNxt = 0;

            mw_indexNxt = mw_index;
            remaning_bits_rNxt = remaning_bits_r;
            decoder_stateNxt = decoder_state;


             MSB_partNxt = MSB_part;

             LSB_partNxt =  LSB_part;
           
             
            

             
    
            if(valid_dec && (column_cnt_dec != (WIDTH)))  column_cnt_decNxt = column_cnt_dec + 1;
            if ((column_cnt_dec == WIDTH) && (valid_dec)) begin
                column_cnt_decNxt = 1;
                line_cnt_decNxt = line_cnt_dec + 1;
                hsynch_decNxt = 1;
            
            end
            if( (line_cnt_dec == (HEIGHT)) && (valid_dec) && (column_cnt_dec == WIDTH)) begin
                line_cnt_decNxt = 1;
                vsynch_decNxt = 1;
            end
            

            

   /*        if(valid_dec  || (valid_in_r && line_cnt_dec == 1 && column_cnt_dec ==1 )) begin
                
                
                we = 1;
                if(adr_1Nxt == WIDTH -1) adr_1Nxt = 0;
                else adr_1Nxt = adr_1 + 1 ;
                if(adr_0Nxt == WIDTH -1)  begin
                    adr_0Nxt = 1;
                    adr_1Nxt = 2;
                end    
                else adr_0Nxt = adr_0 + 1;               



                               

                      
                      
                  
                                                                                                   
            end    */
                                       
            
            
 
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

                        // Uncompressed data case and remaining bits are large enough.
                         if((header_state == 2'b00) && ( remaning_bits >= (DISPARITY_BITS+1))) begin                             

                                decoder_outNxt = {memory_word_buffer[mw_index + DISPARITY_BITS + 1],
                                                memory_word_buffer[mw_index + DISPARITY_BITS ],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 1],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 2],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 3],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 4],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 5],
                                                memory_word_buffer[mw_index + DISPARITY_BITS - 6]};
                                if( remaning_bits == (DISPARITY_BITS+1)) begin
                                     mw_indexNxt = 0;
                                     decoder_stateNxt = 0;
                                     packet_decodedNxt = 1;
                                end                    
                                else mw_indexNxt =  mw_index + DISPARITY_BITS + 2;                
                                            
                                valid_decNxt = 1;
                                                       
                                 we = 1;
                                 
                                if(adr_1Nxt == WIDTH -1) adr_1Nxt = 1;
                                else adr_1Nxt = adr_1 + 1 ;
                                if(adr_0Nxt == WIDTH -1)  begin
                                    adr_0Nxt = 1;
                                    adr_1Nxt = 2;
                                end    
                                else adr_0Nxt = adr_0 + 1;               
                               

                        end
                        // Uncompressed data but the remaining bits are less than 9 bits
                        else if((header_state == 2'b00) && ( remaning_bits < (DISPARITY_BITS+1)) && ( remaning_bits >= 2) ) begin
                            decoder_stateNxt = 2;
                            packet_decodedNxt = 1;
                            remaning_bits_rNxt = (DISPARITY_BITS + 1 ) - remaning_bits;
                            mw_indexNxt = 0;
                            // Store the required LSB part of the uncompressed data according to "remaining bits" value
                            case(remaning_bits)
                      
                                2: LSB_partNxt[0] = {memory_word_buffer[mw_index + 2]};
                                3: LSB_partNxt[1:0] = {memory_word_buffer[mw_index + 3], memory_word_buffer[mw_index + 2]};
                                4: LSB_partNxt[2:0] = {memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2],memory_word_buffer[mw_index + 1]};
                                5: LSB_partNxt[3:0] = {memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2]};                             
                                6: LSB_partNxt[4:0] = {memory_word_buffer[mw_index + 6],memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2]};                                   
                                7: LSB_partNxt[5:0] = {memory_word_buffer[mw_index + 7],memory_word_buffer[mw_index + 6],
                                memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2]};
                                8: LSB_partNxt[6:0] = {memory_word_buffer[mw_index + 8],memory_word_buffer[mw_index + 7],memory_word_buffer[mw_index + 6],
                                memory_word_buffer[mw_index + 5],memory_word_buffer[mw_index + 4],memory_word_buffer[mw_index + 3],
                                 memory_word_buffer[mw_index + 2]};                                                                                                
                            endcase                           
                        end
                        
                                                                  
  
                        // Compressed Data Case
                        else if((header_state != 2'b00) && ( remaning_bits >= 2) ) begin
            
                            mw_indexNxt =  mw_index  + 2;
                            valid_decNxt = 1;
                            
                                   we = 1;
                                if(adr_1Nxt == WIDTH -1) adr_1Nxt = 1;
                                else adr_1Nxt = adr_1 + 1 ;
                                if(adr_0Nxt == WIDTH -1)  begin
                                    adr_0Nxt = 1;
                                    adr_1Nxt = 2;
                                end    
                                else adr_0Nxt = adr_0 + 1;                            
                            if(header_state == 2'b01) begin
                               
                                 decoder_outNxt = decoder_out;
                                 
                            end     
                            else if((header_state == 2'b10) && prev_state == 0)  decoder_outNxt = top_temp_1;
                            else if((header_state == 2'b10) && prev_state != 0)  decoder_outNxt = top_n;
                            else begin
                                  if(prev_state == 0) decoder_outNxt = top_right_temp_1;
                                  else decoder_outNxt = top_right_n;
                                 
                           end   
                            

                         
                        end
                        else if ((header_state != 2'b00) && ( remaning_bits == 1) ) begin
                            mw_indexNxt = 0;
                            valid_decNxt = 1;
                            if(header_state == 2'b01) decoder_outNxt = decoder_out;
                            else if((header_state == 2'b10) && prev_state == 0)  decoder_outNxt = top_temp_1;
                            else if((header_state == 2'b10) && prev_state != 0)  decoder_outNxt = top_n;
                            else begin
                                  if(prev_state == 0) decoder_outNxt = top_right_temp_1;
                                  else decoder_outNxt = top_right_n;
                                 
                           end    
                            decoder_stateNxt = 0; 

                            packet_decodedNxt = 1; 
                                  we = 1;
                                if(adr_1Nxt == WIDTH -1) adr_1Nxt = 1;
                                else adr_1Nxt = adr_1 + 1 ;
                                if(adr_0Nxt == WIDTH -1)  begin
                                    adr_0Nxt = 1;
                                    adr_1Nxt = 2;
                                end    
                                else adr_0Nxt = adr_0 + 1;                                                                     
                        
                        end
  
                        if( (remaning_bits == 1) && (header_state == 2'b00)) begin
                              decoder_stateNxt = 6;
                              packet_decodedNxt = 1;
                              mw_indexNxt = 0;
                              
                        end      

                        else if( (remaning_bits == 0) ) begin
                            decoder_stateNxt = 7;
                            header_state_rNxt[0] = header_state[0];
                            packet_decodedNxt = 1;
                                      
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
                                  we = 1;
                                if(adr_1Nxt == WIDTH -1) adr_1Nxt = 1;
                                else adr_1Nxt = adr_1 + 1 ;
                                if(adr_0Nxt == WIDTH -1)  begin
                                    adr_0Nxt = 1;
                                    adr_1Nxt = 2;
                                end    
                                else adr_0Nxt = adr_0 + 1;                 
                end
                6: begin
                    if(valid_in) memory_word_bufferNxt = memory_word;
                    if(valid_in_r) begin
                        
                         decoder_outNxt = {memory_word_buffer[mw_index + DISPARITY_BITS -1],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 2 ],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 3],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 4],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 5],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 6],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 7],
                                        memory_word_buffer[mw_index + DISPARITY_BITS - 8]};
                       mw_indexNxt = mw_index + DISPARITY_BITS;
                       valid_decNxt = 1; 
                       decoder_stateNxt = 1;    
                                   we = 1;
                                if(adr_1Nxt == WIDTH -1) adr_1Nxt = 1;
                                else adr_1Nxt = adr_1 + 1 ;
                                if(adr_0Nxt == WIDTH -1)  begin
                                    adr_0Nxt = 1;
                                    adr_1Nxt = 2;
                                end    
                                else adr_0Nxt = adr_0 + 1;                                                                                                
                    end               
                end
                
            /*    7: begin // This case is for odd-number memory words, you will need to include buffer confg. as well
                    if(valid_in) memory_word_bufferNxt = memory_word;
                    if(valid_in_r) begin
                        valid_decNxt = 1; 
                        decoder_stateNxt = 1;                     
                        if({header_state[0],header_state_r[0]} == 2'b00) begin
                            mw_indexNxt = mw_index + DISPARITY_BITS + 1;
                            decoder_outNxt = {memory_word_buffer[mw_index + DISPARITY_BITS],
                                        memory_word_buffer[mw_index + 7],
                                        memory_word_buffer[mw_index + 6],
                                        memory_word_buffer[mw_index + 5],
                                        memory_word_buffer[mw_index + 4],
                                        memory_word_buffer[mw_index +3],
                                        memory_word_buffer[mw_index + 2],
                                        memory_word_buffer[mw_index +  1]}; 
                        end
                        
                        else if({header_state[0],header_state_r[0]} == 2'b01) begin
                            mw_indexNxt = mw_index + 1;
                            decoder_outNxt = decoder_out;
                        
                        end
                        else if({header_state[0],header_state_r[0]} == 2'b10) begin
                            mw_indexNxt = mw_index + 1;
                            decoder_outNxt = top_n;
                        
                        end                       
                     
                        else if({header_state[0],header_state_r[0]} == 2'b11) begin
                            mw_indexNxt = mw_index + 1;
                            decoder_outNxt = top_right_n;                          
                        
                        end 

                    end
                
                
                
                end*/

 

                

                
                           
            endcase
      
        
        end
     
    end
endmodule
    

