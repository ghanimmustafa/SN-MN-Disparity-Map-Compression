READ_BINARY_FILE = false; 
if ~exist('encoded_data_file_name', 'var')
    encoded_data_file_name = 'hw_sn_encoded.txt';
end


if(READ_BINARY_FILE == true)
    %% MSB
    %% Convert to 'char' vector:
    char_vector = strsplit(fileread(encoded_data_file_name), {'\r', '\n'})';
    char_vector = char(char_vector);
    
end


