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
      %  processed_map = GTs{dm};
      %  [HEIGHT,WIDTH] = size(processed_map);
        q = floor(processed_map/8);
        q_r = q * 8;
     %   q_r_plus =  q_r + 1; 
      %  q_r_minus =  q_r - 1;
      %   fprintf('dm = %i\n',dm);
         fprintf('PSNR with flooring only = %.2f\n',PSNR(processed_map,q_r));

    %   fprintf('PSNR with flooring and + 1 = %.2f\n',PSNR(processed_map,q_r_plus));
     %   fprintf('PSNR with flooring and -1  = %.2f\n',PSNR(processed_map,q_r_minus));
               
        
    end
    
    
       
end