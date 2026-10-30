% clc
% clear all
% %% MSB
% header_bit = 9;
% text_file_name = 'encoded_output_binary.txt';
% %% Convert to 'char' vector:
% char_vector = strsplit(fileread('encoded_output_binary.txt'), {'\r', '\n'})';
% char_vector = char(char_vector);
compressed_counter = 0;

[rows,columns] = size(char_vector);

for i = 1:rows
    
    if(char_vector(i,header_bit) == '1')
        compressed_counter = compressed_counter + 1;
        
        
    end
    
    
    
    
end


coverage_ratio = 100 * (compressed_counter / (rows))