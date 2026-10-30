MEMORY_WORD_BITS = 128;

READ_BINARY_FILE = true; 
convert_to_binaries = true;

if ~exist('hardware_output_text_file', 'var')
    hardware_output_text_file = 'hw_sn_packets.txt';
end
if(READ_BINARY_FILE == true)
    %% MSB
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

% memory_words_MATLAB = zeros(length(output),MEMORY_WORD_BITS);
% memory_words_MATLAB = output
% [hardware_outputs,bits] = size(memory_words_HW);
% 
% for i = 1:length(MATLAB_memory_words)
%     
%     if(~isequal(memory_words_HW(i,:),MATLAB_memory_words{i}))
%         fprintf('Mismatch result at the memory word of index = %i\n',i);
%     else
%         if( i == length(MATLAB_memory_words))
%             
%             fprintf('All memory words are equal!\n');
%             
%         end
%             
%     end    
%     
%     
%     
%     
% end

