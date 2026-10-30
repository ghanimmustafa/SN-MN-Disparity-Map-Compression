processed_maps(1).DMs_name = Census_DMs;
processed_maps(2).DMs_name = Rank_DMs;
processed_maps(3).DMs_name = CRT_DMs;
for group_index = 1:3
    fprintf('Processed group = %i\n',group_index);
    for dm = 1:length(processed_maps(group_index).DMs_name) %1:length(GTs)

        if(median_filter)
            processed_map = single(processed_maps(group_index).DMs_name(dm).md);
        else
            processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
        end
        image_vector = reshape(processed_map',1,numel(processed_map))';
        quan_counters = zeros(7,1);
       
        for pixel = 1:length(image_vector)
            cnt_index = 0;
            for quan_level = [3,7,15,31,63,127,255]
                
                if(image_vector(pixel) <= quan_level )
                    cnt_index = cnt_index + 1 ;
                    quan_counters(cnt_index) = quan_counters(cnt_index) + 1;
                    
                    
                end
                               
            end
          
        end
      %  [max_value,max_index] = max(quan_counters);
          quan_ratios = round(100 * quan_counters/length(image_vector),2)
                    
    end
    
    
    
end