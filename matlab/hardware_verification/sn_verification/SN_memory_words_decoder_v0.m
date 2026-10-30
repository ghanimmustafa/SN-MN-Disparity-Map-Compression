%% This is for no-wasted bits case ( top to bottom, right to left decoding)

MEMORY_WORD_BITS = 128;
HEADER_BIT = 9;
DISPARITY_BITS = 8;

%decoded_disparities = [];
[HEIGHT,WIDTH] = size(filtered);
total_disparities = HEIGHT * WIDTH;
decoded_disparities = zeros(total_disparities,1);

%k = length(MATLAB_memory_words) * MEMORY_WORD_BITS;
i = 1;
current_bit = MEMORY_WORD_BITS;
mod_cnt = 1;
disparity_index = 0;
while(( i <= length(MATLAB_memory_words)) && ( disparity_index < total_disparities) )
        
       
        %successive_compressed = 0;
        if (current_bit < 1)
            i = i + 1;
            current_bit = MEMORY_WORD_BITS;
            
            
        end


        while( current_bit >= 1)
            disparity_index = disparity_index + 1 ; 
            

            
            if((MATLAB_memory_words{i}(current_bit) == 0) && (current_bit >= HEADER_BIT))
               
             %   disparity_index = disparity_index + 1 ;    
                temp_loc = current_bit - HEADER_BIT + 1;
                decoded_disparities(disparity_index) = bi2de(MATLAB_memory_words{i}(temp_loc:(current_bit-1)),'left-msb');
                current_bit = temp_loc - 1;


            elseif ((MATLAB_memory_words{i}(current_bit) == 0) && (current_bit < HEADER_BIT))

                current_part = MATLAB_memory_words{i}(1:current_bit);
                current_part_length = length(current_part);
                i = i + 1;
                current_bit = MEMORY_WORD_BITS;
                remaining_part_length = HEADER_BIT - current_part_length;
                temp_loc = current_bit - remaining_part_length + 1;
                remaining_part = MATLAB_memory_words{i}(temp_loc:current_bit);
                concatenated_uncompressed = [remaining_part,current_part];
           %     fprintf('concatenated_uncompressed = .. \n');
            %    concatenated_uncompressed
          
                decoded_disparities(disparity_index) = bi2de(concatenated_uncompressed(1:end-1),'left-msb');
                current_bit = temp_loc - 1;


            
            elseif ((MATLAB_memory_words{i}(current_bit) == 1) && (current_bit >= 1))
    
                 decoded_disparities(disparity_index) = decoded_disparities(disparity_index-1);
                 current_bit = current_bit - 1;
                
            end
            
            
%         if((mod(length(decoded_disparities),WIDTH * 5) == 0) && (length(decoded_disparities) ~= 0))
%            
%             if(isequal(decoded_disparities(mod_cnt:end),raster_scan_gt(mod_cnt:length(decoded_disparities) - mod_cnt + 1 )) == 1)
%                 fprintf('%i many pixels are correctly decoded, %i many pixels left .. \n',length(decoded_disparities),total_disparities - length(decoded_disparities));
%                 
%             else
%                 
%                 fprintf('Decoding mismatch detected !! \n');
%                 
%                 
%             end
%              mod_cnt = mod_cnt + WIDTH * 5;
% 
% 
%             
%         end

            if(mod(disparity_index,100000) == 0)
                fprintf('%% %.2f of pixels left to be decoded ..\n',(1 - disparity_index/total_disparities) * 100);
                
            end


        end
       
        

            

end


raster_scan_gt = reshape(filtered',1,numel(filtered))';

if( isequal(raster_scan_gt,decoded_disparities))
    fprintf('Well done !, your decoded image matches with the input image\n');
    
else
    fprintf('Mismatch(s) between input image and decoded image !\n');
    mismatch_locations = find(raster_scan_gt ~= decoded_disparities);
    
end
    
    
    
    
