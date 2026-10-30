MEMORY_WORD_BITS = 128;
HEADER_BIT = 9;
DISPARITY_BITS = 8;


%processed_data = encoded_data_MATLAB(1:10,:);
encoded_data_MATLAB = encode_image(disparity_map);
[total_disparities,columns] = size(encoded_data_MATLAB);
memory_word = zeros(1,MEMORY_WORD_BITS);
shifted_memory_word = zeros(size(memory_word));
shifts_counter = 0;
MATLAB_memory_words ={};
MATLAB_lost_bits = [];
%total_disparities = 20;
for data = 1:total_disparities
    
        if( mod(data,100000) == 0)
            
            fprintf(' %i many data is processed, %i is left\n',data,total_disparities - data);
            fprintf(' %i many words are formed up to now .. \n',length(MATLAB_memory_words));
            
        end
    
        if( encoded_data_MATLAB(data,HEADER_BIT) == 1)

            if( shifts_counter < MEMORY_WORD_BITS)

                if(data == total_disparities)
                    
                   memory_word = ShiftVector(memory_word,1);
                   memory_word(1) = 1;
                  shifts_counter = shifts_counter + 1;
                  remaining_bits = MEMORY_WORD_BITS - shifts_counter;
                  memory_word = ShiftVector(memory_word,remaining_bits);
                  MATLAB_memory_words = [ MATLAB_memory_words,memory_word];
                  break;
                else 
                    
                   
                    memory_word = ShiftVector(memory_word,1);
                    memory_word(1) = 1;
                    shifts_counter = shifts_counter + 1;


                end
                
            else

                remaining_bits = MEMORY_WORD_BITS - shifts_counter;
                memory_word = ShiftVector(memory_word,remaining_bits);
                MATLAB_memory_words = [ MATLAB_memory_words,memory_word];
                
                shifts_counter = 0;
               % memory_word = zeros(1,MEMORY_WORD_BITS);
               if(data == total_disparities)
                memory_word = zeros(1,MEMORY_WORD_BITS);
                memory_word(end) = 1;
                 MATLAB_memory_words = [ MATLAB_memory_words,memory_word];
               else   
              
                memory_word = ShiftVector(memory_word,1);
                memory_word(1) = 1;
                shifts_counter = shifts_counter + 1;
                end
            
            
            end
           

            %memory_word = circshift(memory_word,1);
           
            
           
           % output = [output,memory_word];
            
            
        else
            
            % memory_word = circshift(memory_word,9); 
          
            if( shifts_counter <= ( MEMORY_WORD_BITS - (DISPARITY_BITS +1)))
                if(data == total_disparities)
                  memory_word = ShiftVector(memory_word,(DISPARITY_BITS +1));
                  memory_word(1:(DISPARITY_BITS +1)) = encoded_data_MATLAB(data,:);
                  shifts_counter = shifts_counter + (DISPARITY_BITS +1);

                  remaining_bits = MEMORY_WORD_BITS - shifts_counter;
                  memory_word = ShiftVector(memory_word,remaining_bits);
                  MATLAB_memory_words = [ MATLAB_memory_words,memory_word];
                   break;
                    
                else    
                memory_word = ShiftVector(memory_word,(DISPARITY_BITS +1));
                memory_word(1:(DISPARITY_BITS +1)) = encoded_data_MATLAB(data,:);
                shifts_counter = shifts_counter + (DISPARITY_BITS +1);

                end
            else
                
                remaining_bits = MEMORY_WORD_BITS - shifts_counter;
                
                memory_word = ShiftVector(memory_word,remaining_bits);
                memory_word(1:remaining_bits) = encoded_data_MATLAB(data,(end-remaining_bits+1:end));
                remaining_part = encoded_data_MATLAB(data,1:(DISPARITY_BITS + 1 - remaining_bits));
                
                MATLAB_memory_words = [ MATLAB_memory_words,memory_word];
                memory_word = ShiftVector(memory_word,length(remaining_part));
                memory_word(1:(DISPARITY_BITS + 1 - remaining_bits)) = remaining_part;
                
%                 if ( data == 7)
%                     remaining_part
%                     shifts_counter
%                     lost
%                 end
              
                shifts_counter = length(remaining_part);
               if ( data == total_disparities)
          
                   memory_word = zeros(1,MEMORY_WORD_BITS);
                   memory_word(end - shifts_counter + 1 : end) = remaining_part;
                   MATLAB_memory_words = [ MATLAB_memory_words,memory_word];
                   wasted_bits = MEMORY_WORD_BITS - length(remaining_part);
                   
               end
               
            end

             
            % output = [output,memory_word];
        end   
     

        
    
    
    
    %end

end
    
 %compression_ratio_loss = 100 * ( (sum(sum(MATLAB_lost_bits)))/(total_disparities * DISPARITY_BITS ))   


 
 %% Note that the decoding operation will be bottom --> top in wasted-bits case and top ---> bottom in efficient usage case!