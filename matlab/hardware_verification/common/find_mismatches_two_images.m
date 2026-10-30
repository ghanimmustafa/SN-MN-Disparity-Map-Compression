test = test;
gt = filtered; 

[row,column] = size(gt);

cnt = 0;
for i = 1:row
    
    for j = 1:column
        
        if(gt(i,j) ~= test(i,j))
            
            fprintf('Mismatched pixel at coordinates of %i and %i\n',i,j);
            cnt = cnt + 1;
        end
        
        
        
    end
    
    
    
    
end
fprintf('Total mismatching pixels = %i\n',cnt);