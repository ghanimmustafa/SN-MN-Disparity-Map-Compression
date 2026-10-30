processed_maps(1).DMs = Census_DMs;
processed_maps(1).name = 'Census_DMs';
processed_maps(2).DMs = Rank_DMs;
processed_maps(2).name = 'Rank_DMs';
processed_maps(3).DMs = CRT_DMs;
processed_maps(3).name = 'CRT_DMs';

%psnrs_unfiltered_averages = zeros(7,1);
psnrs_filtered_averages = zeros(7,1);
%psnrs_gts_averages = zeros(7,1);
Q_index_gt = 0;
Q_index = 0;
for Q = [1,2,4,8,16,32,64]
    fprintf('Processing Q = %i\n',Q);
    index = 0; 
    psnrs_unfiltered = zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1);
    psnrs_filtered = zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1);
    for group_index = 1:3
        %fprintf(strcat('Processed group : ',processed_maps(group_index).name,'\n'));
        for dm = 1:length( processed_maps(group_index).DMs) 
    
    
            if(median_filter)
                processed_map = single(processed_maps(group_index).DMs(dm).md);
            else
                processed_map = single(processed_maps(group_index).DMs(dm).disparity_map);
            end
          % processed_map = GTs{dm};
          quan_reduced_dm = floor(processed_map/Q);
          restored_dm = quan_reduced_dm * Q;        
          index = index + 1;
          psnrs_filtered(index) = PSNR(restored_dm,processed_map);
             
                    
        end
        
    end
    Q_index = Q_index + 1;
    %psnrs_unfiltered_averages(Q_index) = mean(psnrs_unfiltered);
    psnrs_filtered_averages(Q_index) = mean(psnrs_filtered);
    %fprintf('Avg. PSNR for generated DMs = %.2f\n',mean(psnrs));
    
%     %% For GTs:
%     psnrs_gts = zeros(length(GTs),1);
%     for gt = 1:length(GTs)
%         quan_reduced_dm = floor(GTs{gt}/Q);
%         restored_dm = quan_reduced_dm * Q;
%         psnrs_gts(gt) = PSNR(restored_dm,GTs{gt});   
%     end
%     Q_index_gt = Q_index_gt + 1;
%     psnrs_gts_averages(Q_index_gt) = mean(psnrs_gts);
    %fprintf('Avg. PSNR for GTs = %.2f\n',mean(psnrs_gts));

end
