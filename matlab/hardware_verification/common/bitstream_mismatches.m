gt = MN_encoded_gt;
test = MN_test;
[HEIGHT,WIDTH] = size(processed_map);
cnt = 0;
for i = 1:length(gt)
    
    if(test(i,:) ~= gt(i,:))
       fprintf('A mismatch occured at pixel = %i\n',i);
       cnt = cnt + 1;
        
    end
    
    
    
end
cnt