function encoded_data_MATLAB= encode_image(image)

HEADER_BIT = 9;
DISPARITY_BITS = 8;
[HEIGHT,WIDTH] = size(image);

encoded_data_MATLAB = zeros(HEIGHT * WIDTH,DISPARITY_BITS + 1);
encoded_data_MATLAB(1,:) = [de2bi(image(1,1),DISPARITY_BITS,'left-msb'),0];

image_vector = reshape(image',1,numel(image))';

for i = 2:length(image_vector)
    
    if ( image_vector(i) == image_vector(i-1))
        
        encoded_data_MATLAB(i,:) = [de2bi(image_vector(i),DISPARITY_BITS,'left-msb'),1];
        
        
    else
        
        encoded_data_MATLAB(i,:) = [de2bi(image_vector(i),DISPARITY_BITS,'left-msb'),0];
        
        
    end
    
    
    
    
end