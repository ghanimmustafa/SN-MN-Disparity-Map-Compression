[HEIGHT,WIDTH]= size(hw_decoded_map);
cnt = 0;
for row = 1:HEIGHT
    
    for column = 1: WIDTH
        
        
        if(hw_decoded_map(row,column) ~= reference_map(row,column))
            
            fprintf('Unequal location at ROW = %i and COLUMN = %i\n',row,column);
            cnt = cnt + 1;
            
        end
        
        
    end
    
    
end

fprintf('TOTAL UNEQUAL VALUES = %i\n',cnt);