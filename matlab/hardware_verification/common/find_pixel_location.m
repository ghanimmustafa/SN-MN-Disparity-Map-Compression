function [row,col] = find_pixel_location(index_at_bistream,base_img)

[height,width] = size(base_img);

row = ceil(index_at_bistream/width);
    if(row == 1)
        col = index_at_bistream;
    else
        
        col = index_at_bistream - (row-1)*width;
    end



end