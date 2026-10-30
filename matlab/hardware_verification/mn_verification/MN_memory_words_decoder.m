%% This is for no-wasted bits case ( top to bottom, right to left decoding)

MEMORY_WORD_BITS = 128;
HEADER_BIT = 10;
DISPARITY_BITS = 8;
test_img = test_1920p;
%decoded_disparities = [];
[HEIGHT,WIDTH] = size(test_1920p);
total_disparities = HEIGHT * WIDTH;
decoded_disparities = zeros(total_disparities,1);

%k = length(MATLAB_memory_words) * MEMORY_WORD_BITS;
i = 1;
current_bit = MEMORY_WORD_BITS;
mod_cnt = 1;
disparity_index = 0;
total_MWs = mw_index;
%MATLAB_memory_words = test_packets;
while(( i <= total_MWs) && ( disparity_index < total_disparities) )
        
        
       
        %successive_compressed = 0;
        if (current_bit < 1)
            i = i + 1;
            current_bit = MEMORY_WORD_BITS;
            
            
        end


        while( ( i <= total_MWs) && (current_bit >= 1) && (disparity_index < total_disparities))
           
            disparity_index = disparity_index + 1 ; 
            
            left_n = disparity_index - 1;
            top_n = mod(disparity_index,WIDTH) + (floor(disparity_index/WIDTH) - 1) * WIDTH;
            top_right_n = top_n + 1; 
            
            if(isequal(MATLAB_memory_words(i,current_bit-1:current_bit),[0 0]) && (current_bit >= HEADER_BIT))
               
             %   disparity_index = disparity_index + 1 ;    
                temp_loc = current_bit - HEADER_BIT + 1;
                decoded_disparities(disparity_index) = bi2de(MATLAB_memory_words(i,temp_loc:(current_bit-2)),'left-msb');
                current_bit = temp_loc - 1;


            elseif ((isequal(MATLAB_memory_words(i,current_bit-1:current_bit),[0 0]) &&  (current_bit < HEADER_BIT) &&  (current_bit >= 2)))

                current_part = MATLAB_memory_words(i,1:current_bit);
                current_part_length = length(current_part);
                i = i + 1;
                current_bit = MEMORY_WORD_BITS;
                remaining_part_length = HEADER_BIT - current_part_length;
                temp_loc = current_bit - remaining_part_length + 1;
                remaining_part = MATLAB_memory_words(i,temp_loc:current_bit);
                concatenated_uncompressed = [remaining_part,current_part];
           %     fprintf('concatenated_uncompressed = .. \n');
            %    concatenated_uncompressed
          
                decoded_disparities(disparity_index) = bi2de(concatenated_uncompressed(1:end-2),'left-msb');
                current_bit = temp_loc - 1;


            elseif ((MATLAB_memory_words(i,current_bit) == 0) && (MATLAB_memory_words(i+1,MEMORY_WORD_BITS) == 0) &&  (current_bit == 1))

                current_part = MATLAB_memory_words(i,current_bit);
                current_part_length = 1;
                i = i + 1;
                current_bit = MEMORY_WORD_BITS;
                remaining_part_length = HEADER_BIT - current_part_length;
                temp_loc = current_bit - remaining_part_length + 1;
                remaining_part = MATLAB_memory_words(i,temp_loc:current_bit);
                concatenated_uncompressed = [remaining_part,current_part];

          
                decoded_disparities(disparity_index) = bi2de(concatenated_uncompressed(1:end-2),'left-msb');
                current_bit = temp_loc - 1;
            %% Compressed Cases below .. :    
            
            elseif ((MATLAB_memory_words(i,current_bit) == 1) && (MATLAB_memory_words(i,current_bit-1) == 0) && (current_bit >= 2))
    
                 decoded_disparities(disparity_index) = decoded_disparities(left_n);
                 if(current_bit > 2)
                     current_bit = current_bit - 2;
                 elseif(current_bit == 2)
                     
                     current_bit = MEMORY_WORD_BITS;
                     i = i + 1;
                     
                 end
                 
                 
            elseif ((MATLAB_memory_words(i,current_bit) == 0) && (MATLAB_memory_words(i,current_bit-1) == 1) && (current_bit >= 2))
    
                 decoded_disparities(disparity_index) = decoded_disparities(top_n);
                 if(current_bit > 2)
                     current_bit = current_bit - 2;
                 elseif(current_bit == 2)
                     
                     current_bit = MEMORY_WORD_BITS;
                     i = i + 1;
                     
                 end
                 
             elseif ((MATLAB_memory_words(i,current_bit) == 1) && (MATLAB_memory_words(i,current_bit-1) == 1) && (current_bit >= 2))
    
                 decoded_disparities(disparity_index) = decoded_disparities(top_right_n);
                 if(current_bit > 2)
                     current_bit = current_bit - 2;
                 elseif(current_bit == 2)
                     
                     current_bit = MEMORY_WORD_BITS;
                     i = i + 1;
                     
                 end        
                 
            elseif ((MATLAB_memory_words(i,current_bit) == 1) && (MATLAB_memory_words(i+1,MEMORY_WORD_BITS) == 0) && (current_bit == 1))
    
                 decoded_disparities(disparity_index) = decoded_disparities(left_n);
                 current_bit = MEMORY_WORD_BITS-1;
                 i = i + 1;

            elseif ((MATLAB_memory_words(i,current_bit) == 0) && (MATLAB_memory_words(i+1,MEMORY_WORD_BITS) == 1) && (current_bit == 1))
    
                 decoded_disparities(disparity_index) = decoded_disparities(top_n);
                 current_bit = MEMORY_WORD_BITS-1;
                 i = i + 1;            
            elseif ((MATLAB_memory_words(i,current_bit) == 1) && (MATLAB_memory_words(i+1,MEMORY_WORD_BITS) == 1) && (current_bit == 1))
    
                 decoded_disparities(disparity_index) = decoded_disparities(top_right_n);
                 current_bit = MEMORY_WORD_BITS-1;
                 i = i + 1;
                 
            end

            if(mod(disparity_index,100000) == 0)
                fprintf('%% %.2f of pixels left to be decoded ..\n',(1 - disparity_index/total_disparities) * 100);
                
            end


        end
       
        

            

end


raster_scan_gt = reshape(test_img',1,numel(test_img))';

if( isequal(raster_scan_gt,decoded_disparities))
    fprintf('Well done !, your decoded image matches with the input image\n');
    
else
    fprintf('Mismatch(s) between input image and decoded image !\n');
    mismatch_locations = find(raster_scan_gt ~= decoded_disparities);
    
end
    
    
    
    
