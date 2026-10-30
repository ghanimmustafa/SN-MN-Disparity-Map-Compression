function Xored_image = XOR_an_image(image)
image = uint8(image);
[HEIGHT,WIDTH] = size(image);

Xored_image = zeros(HEIGHT,WIDTH);
for row = 1:HEIGHT
    for column = 1:WIDTH
        if(row == 1 && column == 1)
            Xored_image(row,column) = bi2de(bi2gray(de2bi(image(row,column))));
        elseif( row > 1 && column == 1)
            Xored_image(row,column )= bi2de(bi2gray(de2bi(image(row-1,WIDTH),image(row,column))));
        else
            Xored_image(row,column) = bi2de(bi2gray(de2bi(image(row,column - 1),image(row,column))));
            
        end
        
        
               
    end
    
    
    
end


end