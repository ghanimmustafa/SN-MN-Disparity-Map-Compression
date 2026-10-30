function y = Image_to_Hex_Vector(image_name,output_file_name)


image_vector = reshape(image_name',1,numel(image_name))';
y = dec2hex(image_vector);

fprintf('The output Hexdecimal Image file is being written..\n');

dlmwrite(output_file_name, y, 'delimiter','','newline','pc');



end