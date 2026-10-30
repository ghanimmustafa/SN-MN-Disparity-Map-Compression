 %processed_maps = Rank_DMs ;
 
for thres = [0,1,3]
    fprintf('Delta = %i\n',thres);
%
% for DMs_index = 1: 3
%     if(DMs_index == 1)
%         processed_maps = Rank_DMs;
%         getVarName(Rank_DMs)
%     elseif(DMs_index == 2)
%          processed_maps = CRT_DMs;
%          getVarName(CRT_DMs)
%     else
%          processed_maps = Census_DMs;
%          getVarName(Census_DMs)
%     end
    processed_maps = GTs;
    for dm = 1:length(processed_maps)
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
            compressed_locations = zeros(length(image_vector),1);
            comp_index = 0;
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
                 
                        
                   % fprintf('left_n = %.2f, current = %.2f\n',left_n,current);
                    
                    
                   
                    comp_index = comp_index + 1;
                    compressed_locations(comp_index) = pixel;

                end

            end
            fprintf('%.2f\n',find_mean_consecutivity_SN(compressed_locations,comp_index));



    end


%end
        




end





%         [HEIGHT,WIDTH] = size(processed_map);
%         cnt = 0;
%         for row=1:HEIGHT
%            
%                 for column = 1:WIDTH
%                     if((column == 1)  && (row == 1))
%                         left_n = NaN;
%                     elseif((column == 1)  && (row > 1))
%                         
%                         left_n = processed_map(row-1,WIDTH);
%                         
%                     else
%                         left_n = processed_map(row,column-1);
%                     end
% 
%                     
%                     current = processed_map(row,column);
%                     flag = 1;
% 
%                     if((abs(left_n - current) <= thres)) %% for integer based
%                    % comparsions
% 
% 
%                %    if( (abs(left_n - current) == thres)  || (abs(left_n - current) == (thres-1)) || (abs(left_n - current) == (thres-2)) || (abs(left_n - current) == (thres-3)) || (abs(left_n - current) == (thres-7)))
%                 
%                           cnt = cnt + 1;
%                           
%                           fprintf('cnt = %i\n',cnt);
%                           
%                    end
%                     
%                     if( thres == 0)
%                          header_bits = 1;
% 
%                     elseif ( thres == 1)
%                          header_bits = 2;
% 
%                      elseif ( thres == 3)
%                          header_bits = 3;
% 
%                      elseif ( thres == 7)
%                          header_bits = 4;
%                     %     fprintf('Coverage ratio = %.2f\n',coverage_ratio_norm * 100);
% 
%                      elseif ( thres == 15)
%                          header_bits = 5;
% 
% 
%                     end
% 
%                end
% 
% 
%         end
%      %   coverage_ratio_norm =  cnt/((WIDTH*HEIGHT));
%       %  compression_ratio = 100 * (orginal_bits - (coverage_ratio_norm * header_bits + ( 1 - coverage_ratio_norm) * ( header_bits + orginal_bits)))/orginal_bits;
% 
%        % fprintf('%.2f\n',compression_ratio);
%     %   fprintf('Run Length = %.2f\n',cnt);

    