% 
% MATLAB_results = MATLAB_memory_words;
% hw_results = BinaryFileToBinaryArray('HW_HLB_MN_DataPackets_test_720p.txt');
% gt = MATLAB_results;
% test = hw_results;
% 
% cnt = 0;
% [pixels,bits] = size(gt);
% 
% for i=1:pixels
%     if(~isequal(gt(i,:),test(i,:)))
%         cnt = cnt + 1;
%         [row,col] = find_pixel_location(i,test_1920p);
%         fprintf('Mismatch at pixel = %i\n',i);
%         fprintf('Exists at row = %i, column = %i\n',row,col);
%     
%     end
% 
% 
% end
% if(cnt == 0)
%     fprintf('Both bitstreams are equal!\n');
% end

[HEIGHT,WIDTH] = size(filtered);

for row = 1:HEIGHT
    for column = 1:WIDTH
        if(filtered(row,column) ~= decoded_img(row,column))
            fprintf('row = %i,column = %i\n',row,column);
            break;
        end
    end
    
end