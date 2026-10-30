processed_maps(1).DMs_name = Census_DMs;
processed_maps(2).DMs_name = Rank_DMs;
processed_maps(3).DMs_name = CRT_DMs;
%space_savings = zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1);
WINDOW_SIZE = 2;
img_index = 0;
space_savings = zeros(length(GTs),1);
% for group_index = 1:3
%     fprintf('Processed group = %i\n',group_index);
    for dm = 1:length(GTs)%length(processed_maps(group_index).DMs_name) %1:length(GTs)
        processed_map = GTs{dm};
%         if(median_filter)
%             processed_map = single(processed_maps(group_index).DMs_name(dm).md);
%         else
%             processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
%         end
        image_vector = reshape(processed_map',1,numel(processed_map))';
        compressed_bits = 0; 
        n = numel(processed_map);
        max_integer_bits = ceil(log2(max(max(processed_map))));
        uncompressed_bits = length(image_vector) * max_integer_bits;
        fprintf('Max integer bits = %i\n',max_integer_bits);
        partitioned_frame  = mat2cell(image_vector,diff([0:WINDOW_SIZE:n-1,n]));
        for cell=1:length(partitioned_frame)
            for pixel=1:length(partitioned_frame{cell})
                 if(all((partitioned_frame{cell} <= 127)))
                    

                     used_bits = 7;
                 else
                     used_bits = max_integer_bits;
                 end
                 current_d = partitioned_frame{cell}(pixel);
                if(pixel == 1 && cell == 1)
                    left_d = NaN;
                elseif(pixel == 1 && cell > 1)
                    left_d = partitioned_frame{cell-1}(end);
                else
                    
                    left_d = partitioned_frame{cell}(pixel-1);
                end
                if(current_d == left_d)
                    compressed_bits = compressed_bits + 1;
                else
                    compressed_bits = compressed_bits + 1 + used_bits;
                end               
                
            end
            % for quan-heading bit
            compressed_bits = compressed_bits + 1;
            
        end
          
        
        img_index = img_index + 1;
        space_savings(img_index) = 100 * ( 1 - compressed_bits/uncompressed_bits);
        fprintf('Space savings = %.2f\n',space_savings(img_index));
        
                   
    end
    %average_space_savings(group_index) = mean(space_savings);
    
    
    
%end

fprintf('Average Space Savings = %.2f\n',mean(space_savings));


%             if(pixel >= 5)
%                 my_window = image_vector(pixel-QUANT_REDUCTION_WINDOW+1:pixel); 
%                 
%             end
% 
%         for pixel = 1:length(image_vector)
%             current_d = image_vector(pixel);
%             if(pixel == 1)
%                 left_d = NaN;
%             else
%                 left_d = image_vector(pixel-1);
%             end
%             if(current_d == left_d)
%                 compressed_bits = compressed_bits + 1;
%             else
%                 compressed_bits = compressed_bits + 1 + 8;
%             end
