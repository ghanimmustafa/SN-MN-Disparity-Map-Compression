 %processed_maps = Rank_DMs ;
 GTs = 0;
for thres = 3
    fprintf('Delta = %i\n',thres);
%
for DMs_index = 1: 3
    if(DMs_index == 1)
        processed_maps = Rank_DMs;
        getVarName(Rank_DMs)
    elseif(DMs_index == 2)
         processed_maps = CRT_DMs;
         getVarName(CRT_DMs)
    else
         processed_maps = Census_DMs;
         getVarName(Census_DMs)
    end
 %   processed_maps = GTs;
    for dm = 1:length(processed_maps)
            cnt = 0;
            if(isequal(processed_maps,GTs))
                processed_map = GTs{dm};
                
            else
                

                if(median_filter)
                    processed_map = single(processed_maps(dm).md);

                else
                    processed_map = single(processed_maps(dm).disparity_map);

                end
                
            end

        %    orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
            image_vector = reshape(processed_map',1,numel(processed_map))';
            orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
            for pixel = 1:length(image_vector)

                if((pixel == 1))
                    left_n = NaN;
                else
                    left_n = image_vector(pixel-1);
                end


                current = image_vector(pixel);

                diff = (abs(left_n - current));
                if((diff <= thres) && ((floor(diff) == diff) || ( diff == thres) )) %% for integer based
               % comparsions
                    cnt = cnt + 1;
                 
                        
                   % fprintf('left_n = %.2f, current = %.2f\n',left_n,current);
                    
                    
  
                end
                if(thres == 0)
                    header_bits = 1;
                    
                elseif( thres == 1)
                    header_bits = 3;
                    
                else
                     header_bits = 4;
                    
                end
                

                

            end
                coverage_ratio = cnt/length(image_vector);
                space_savings = (orginal_bits - (coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( 1 + orginal_bits)))/orginal_bits;
                fprintf('%.2f\n',100 * space_savings);


    end


end
        




end

