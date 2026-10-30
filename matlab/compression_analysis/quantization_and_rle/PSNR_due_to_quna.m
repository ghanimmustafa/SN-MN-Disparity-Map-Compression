processed_maps(1).DMs = Census_DMs;
processed_maps(1).name = 'Census_DMs';
processed_maps(2).DMs = Rank_DMs;
processed_maps(2).name = 'Rank_DMs';
processed_maps(3).DMs = CRT_DMs;
processed_maps(3).name = 'CRT_DMs';

psnrs = zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1);
index = 0;
reduction_factor = 4;
for group_index = 1:3
    fprintf(strcat('Processed group : ',processed_maps(group_index).name,'\n'));
    for dm = 1:length( processed_maps(group_index).DMs) 


        if(median_filter)
            processed_map = single(processed_maps(group_index).DMs(dm).md);
        else
            processed_map = single(processed_maps(group_index).DMs(dm).disparity_map);
        end
      % processed_map = GTs{dm};
      quan_reduced_dm = floor(processed_map/reduction_factor);
      restored_dm = quan_reduced_dm * reduction_factor;
    
      index = index + 1;
      psnrs(index) = PSNR(restored_dm,processed_map);
      
      
      
    end
    
end

fprintf('Avg. PSNR = %.2f\n',mean(psnrs));

%% For GTs:
psnrs_gts = zeros(length(GTs),1);
for gt = 1:length(GTs)
    quan_reduced_dm = floor(GTs{gt}/reduction_factor);
    restored_dm = quan_reduced_dm * reduction_factor;
    psnrs_gts(gt) = PSNR(restored_dm,GTs{gt});
   
    
    
    
end
fprintf('Avg. PSNR for GTs = %.2f\n',mean(psnrs_gts));

