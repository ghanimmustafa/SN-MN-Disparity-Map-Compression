function binary_array =  BinaryFileToBinaryArray(text_file_name)




    %% MSB
    %% Convert to 'char' vector:
    char_vector = strsplit(fileread(text_file_name), {'\r', '\n'})';
    binary_array = char(char_vector)-'0';
















end