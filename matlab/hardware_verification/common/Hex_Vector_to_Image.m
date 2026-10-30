function y = Hex_Vector_to_Image(file_name,reference_image)

[height,width] = size(reference_image);
% read the hex file of the image
fileID = fopen(file_name,'r');
converted_decimals_vector = fscanf(fileID,"%X");
y = reshape(converted_decimals_vector,width,height)';
% Shift the output image to left in order to remove shifting effect due to
% 'reset' state
%y = circshift(output_image,[0,-1]);
% write both of input and output images..
fprintf('Writing hardware-based produced output image ..\n');
imwrite(uint8(rescale(y,0,255)),'HW_output_image.png');
end