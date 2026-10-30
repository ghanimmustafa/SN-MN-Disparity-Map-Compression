%% This is for no-wasted bits case ( top to bottom, right to left decoding)
%% This script deocdes memory words exported by the hardware design, in a 2D array form. 

MEMORY_WORD_BITS = 128;
HEADER_BIT = 9;
DISPARITY_BITS = 8;
%% "disparity_map" is the reference disparity map in the workspace.
[HEIGHT,WIDTH] = size(disparity_map);
total_disparities = HEIGHT * WIDTH;

decoded_disparities = zeros(total_disparities,1);

%% Import the HW memory word packets
%% Make the following two options "true" if you want to import. 
READ_BINARY_FILE = true; 
convert_to_binaries = true;

if ~exist('hardware_output_text_file', 'var')
    hardware_output_text_file = 'hw_sn_packets.txt';
end
if(READ_BINARY_FILE == true)
    %% Convert to 'char' vector:
    char_vector = strsplit(fileread(hardware_output_text_file), {'\r', '\n'})';
    char_vector = char(char_vector);
    
end


if(convert_to_binaries == true)
    memory_words_HW = str2num(char_vector(:,1));
    for i = 2:MEMORY_WORD_BITS
        memory_words_HW = [memory_words_HW,str2num(char_vector(:,i))];


    end
end    

i = 1;
current_bit = MEMORY_WORD_BITS;
mod_cnt = 1;
disparity_index = 0;
[memory_words_length,word_bits] = size(memory_words_HW);
%% Start decoding operation
%% Current bit always has to be the header bit ( flag bit)
%% Use while instead of for loops since we don't know the exact flow of decoding operation and who many instances  it does require. 
% 'i' is the current memory word number (index)
while(( i <= memory_words_length) && ( disparity_index < total_disparities) )
    
        % Start from the 128th bit for a new memory word. 
        if (current_bit < 1)
            i = i + 1;
            current_bit = MEMORY_WORD_BITS;
            
            
        end


        while( (current_bit >= 1)  && ( disparity_index < total_disparities) )
            
            

            
            if((memory_words_HW(i,current_bit) == 0) && (current_bit >= HEADER_BIT))
               
 
                temp_loc = current_bit - HEADER_BIT + 1;
                disparity_index = disparity_index + 1 ; 
                
                decoded_disparities(disparity_index) = bi2de(memory_words_HW(i,(temp_loc:(current_bit-1))),'left-msb');
                current_bit = temp_loc - 1;


            elseif ((memory_words_HW(i,current_bit) == 0) && (current_bit < HEADER_BIT))

                current_part = memory_words_HW(i,(1:current_bit));
                current_part_length = length(current_part);
                i = i + 1;
                current_bit = MEMORY_WORD_BITS;
                remaining_part_length = HEADER_BIT - current_part_length;
                temp_loc = current_bit - remaining_part_length + 1;
                remaining_part = memory_words_HW(i,(temp_loc:current_bit));
                concatenated_uncompressed = [remaining_part,current_part];

                disparity_index = disparity_index + 1 ; 
                
                decoded_disparities(disparity_index) = bi2de(concatenated_uncompressed(1:end-1),'left-msb');
                current_bit = temp_loc - 1;


            
            elseif ((memory_words_HW(i,(current_bit)) == 1) && (current_bit >= 1))
                 disparity_index = disparity_index + 1 ; 
   
                 decoded_disparities(disparity_index) = decoded_disparities(disparity_index-1);
                 current_bit = current_bit - 1;
                
            end
            
            


            if(mod(disparity_index,100000) == 0)
                fprintf('%% %.2f of pixels left to be decoded ..\n',(1 - disparity_index/total_disparities) * 100);
                
            end


        end
       
        

            

end

%% Verify the decoding results
raster_scan_gt = reshape(disparity_map',1,numel(disparity_map))';

if( isequal(raster_scan_gt,decoded_disparities))
    fprintf('Well done !, your decoded image matches with the input image\n');
    
else
    fprintf('Mismatch(s) between input image and decoded image !\n');
    mismatch_locations = find(raster_scan_gt ~= decoded_disparities);
    
end
    
    
    
    
