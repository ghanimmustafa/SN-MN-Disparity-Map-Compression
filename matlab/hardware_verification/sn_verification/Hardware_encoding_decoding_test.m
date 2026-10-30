
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


ground_truth_img = filtered;
[HEIGHT,WIDTH] = size(ground_truth_img);
HEADER_BIT = 9;
image_vector = reshape(ground_truth_img',1,numel(ground_truth_img))';

MATLAB_flagged_vector = zeros(length(image_vector),1);

header_bit_column = char_vector(:,HEADER_BIT);


for i = 2:length(image_vector)
    
    if((image_vector(i) == image_vector(i-1)))
        MATLAB_flagged_vector(i) = 1;
        
    end
    

        
    
    
end
hardware_flagged_vector = zeros(length(header_bit_column),1);
for i = 1:length(header_bit_column)
    
    if(header_bit_column(i) == '1')
        hardware_flagged_vector(i) = 1;
        
        
    end
    
    
    
end

MATLAB_ground_truth_img = reshape(MATLAB_flagged_vector,WIDTH,HEIGHT)';
%% cut the last value from the hardware-based encoded vector to equalize vectors length. 
hardware_flagged_vector = hardware_flagged_vector(1:(end-1));
if(isequal(MATLAB_flagged_vector,hardware_flagged_vector))
    fprintf('Hardware testbench output and MATLAB generated output are equal\n');
    
else
    fprintf('Hardware testbench output and MATLAB generated output are NOT equal\n');
    
end

 Hardware_encoded_img = reshape(hardware_flagged_vector,WIDTH,HEIGHT)';

 fprintf('Hardware Vector Coverage Ratio = %.2f\n',(100 * sum(hardware_flagged_vector)/length(hardware_flagged_vector)));
  fprintf('MATLAB Vector Coverage Ratio = %.2f\n',(100 * sum(MATLAB_flagged_vector)/length(MATLAB_flagged_vector)));

% Testing the ability to decode the generated hardware vectors..

[values,bit_locations] = size(char_vector);

decoded_img = zeros(values,1);
decoded_img(:,1) = char_vector(:,1);
 decoded_img(1) = bin2dec(char_vector(1,1:(end-1)));

for i = 2: values
    if ((strcmp(char_vector(i,HEADER_BIT),'1')))
        k = i-1;
        while (strcmp(char_vector(k,HEADER_BIT),'1'))
            k = k - 1;
        end
        left_neighbour = char_vector(k,:);
        decoded_img(i) = bin2dec(left_neighbour(1:(end-1)));
    else
         decoded_img(i) = bin2dec(char_vector(i,1:(end-1)));
    end
    
end
%decoded_img = decoded_img(1:(end-1));

decoded_img = reshape(decoded_img,WIDTH,HEIGHT)';


if(isequal(decoded_img,ground_truth_img))
    fprintf('Decoded image from hardware and the orginal image are equal\n');
    
else
    fprintf('Decoded image from hardware and the orginal image are NOT equal\n');
    
end