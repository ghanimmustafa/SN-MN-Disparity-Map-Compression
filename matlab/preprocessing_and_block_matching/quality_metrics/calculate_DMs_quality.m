%% Select your quality metric:

IS_PSNR = true;
IS_RMSE = false;
IS_ACC_ABS = false;
MAX_ABS_DIFF = 10;
FILTER_SIZE = 3;
Rank_DMs_5x5_search = Rank_DMs(1:2:end);
Rank_DMs_7x7_search = Rank_DMs(2:2:end);
CRT_DMs_5x5_search = CRT_DMs(1:2:end);
CRT_DMs_7x7_search = CRT_DMs(2:2:end);
processed_maps(1).DMs_name = Rank_DMs_5x5_search;
processed_maps(2).DMs_name = Rank_DMs_7x7_search;
processed_maps(3).DMs_name = CRT_DMs_5x5_search;
processed_maps(4).DMs_name = CRT_DMs_7x7_search;
processed_maps(5).DMs_name = Census_DMs;

for group_index = 1:5
        %fprintf('Processed group = %i\n',group_index);
        metrics = zeros(length(processed_maps(group_index)));
        k = 0;
        for dm = 1:length(processed_maps(group_index).DMs_name)  %length(GTs) %
        %    if(group_index == 3)
         %       k = k + 1;
         %   else
          %      if(mod(dm,2) ~= 0)
          %         k = k + 1;        
           %     end
           % end           
            
            gt = GTs{dm};
            if(median_filter)
                processed_map = double(processed_maps(group_index).DMs_name(dm).md);
            else
                processed_map = double(processed_maps(group_index).DMs_name(dm).disparity_map);
            end
            processed_map = non_padded_median_filters(processed_map,FILTER_SIZE,FILTER_SIZE);
            %% Make dimensions match:
            [height_proc,width_proc] = size(processed_map);
            [height_gt,width_gt] = size(gt);
            min_height = min(height_proc,height_gt);
            min_width = min(width_proc,width_gt);
            processed_map = processed_map(1:min_height,1:min_width);
            gt = gt(1:min_height,1:min_width);
            if(IS_PSNR)
                metric = PSNR(gt,processed_map);
            elseif(IS_RMSE)
                metric = sqrt(immse(gt, processed_map));                
            
            elseif(IS_ACC_ABS)
                metric = numel(find(abs(gt-processed_map) <= MAX_ABS_DIFF));
                metric = 100 * (metric/numel(gt));
            end
            
            metrics(dm) = metric;

        end
        fprintf('%.2f\n',mean(metrics));
        
        
        
        
        
end