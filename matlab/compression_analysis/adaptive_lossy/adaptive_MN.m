%% Applying optimal delta for each line ( using SN)
METHOD = 'OPT';
processed_maps(1).DMs_name = Census_DMs;
processed_maps(2).DMs_name = Rank_DMs;
processed_maps(3).DMs_name = CRT_DMs;
for group_index = 1:3
    fprintf('Processed group = %i\n',group_index);



for dm = 1:length(processed_maps(group_index).DMs_name)

        if(median_filter)
            processed_map = single(processed_maps(group_index).DMs_name(dm).md);
        else
            processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
        end


     orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
    [HEIGHT,WIDTH] = size(processed_map);
    %% For GT with subpixel
 %   max_integer_bits = ceil(log2(max(max(GTs{dm}))));

  %  orginal_bits = max_integer_bits + fraction_bits;
    line_SRs = zeros(HEIGHT,3);
    optimal_line_SRs = zeros(HEIGHT,2);   
    for row=1:HEIGHT
        index = 0;
        for thres = [0,1,3]
            cnt = 0;
            index = index + 1;
            for column =1:WIDTH

                
                if((column == WIDTH) || (row == 1))
                    top_right_neighbour = 0;
                    
                else
                    top_right_neighbour = processed_map(row-1,column+1);
                    
                end
                   
                if(row == 1)
                    top_neighbour = 0;
                    
                    
                else
                    top_neighbour = processed_map(row-1,column);
                    
                end
                    
                if((column == 1) && (row ~= 1))
                     left_neighbour = processed_map(row-1,WIDTH);
                     
                     
                elseif((column == 1) && (row == 1))
                    left_neighbour = 0;
  
                else 
                     left_neighbour = processed_map(row,column-1);
                                   
                end
                current_pixel_cost = processed_map(row,column);
                diff1 = abs(current_pixel_cost - left_neighbour);
                diff2 = abs(current_pixel_cost - top_neighbour);
                diff3 = abs(current_pixel_cost - top_right_neighbour);
                cond1 = (diff1 == thres)|| (diff1 == (thres-1)) || (diff1 == (thres-2)) || (diff1 == (thres-3));
                cond2 = (diff2 == thres)|| (diff2 == (thres-1)) || (diff2 == (thres-2)) || (diff2 == (thres-3));
                cond3 = (diff3 == thres)|| (diff3 == (thres-1)) || (diff3 == (thres-2)) || (diff3 == (thres-3));
                %(diff <= thres) && ((floor(diff) == diff) || ( diff == thres)
                if((diff1 <= thres)|| (diff2 <= thres) || (diff3 <= thres))

                      cnt = cnt + 1;

               end               
                
        %     if ((diff1 <= thres)|| (diff2 <= thres) || (diff3 <= thres))




          %            cnt = cnt + 1;
         %    end
                coverage_ratio_norm =  cnt/((WIDTH));
                if( thres == 0)
                     header_bits = 2;

                elseif ( thres == 1)
                     header_bits = 4;
                     
                 elseif ( thres == 3)
                     header_bits = 5;
                     
    
                     
                     
                end
                compression_ratio = 100 * (orginal_bits - (coverage_ratio_norm * header_bits + ( 1 - coverage_ratio_norm) * ( header_bits + orginal_bits)))/orginal_bits;



            end
                line_SRs(row,index) = compression_ratio;
                

        end   

    end

    [optimal_line_SRs(:,1),optimal_line_SRs(:,2)] = max(line_SRs,[],2);

    optimal_frame_SR = sum(optimal_line_SRs(:,1))/HEIGHT;
    
    semi_optimal_SRs = last_line_delta_same(line_SRs,optimal_line_SRs,1);
    
    semi_optimal_frame_SR = sum(semi_optimal_SRs(:,1))/HEIGHT;
    
    delta0_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 1)/HEIGHT;
    delta1_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 2)/HEIGHT;
    delta3_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 3)/HEIGHT;
    
    delta0_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 1)/HEIGHT;
    delta1_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 2)/HEIGHT;
    delta3_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 3)/HEIGHT;    

    orginal_frame_size = orginal_bits * WIDTH * HEIGHT;
    wasted_bits_by_delta_sel = 2 * HEIGHT;
    compressed_frame_size_opt = ((100 - optimal_frame_SR)/100) * orginal_frame_size + wasted_bits_by_delta_sel;
    compressed_frame_size_semi = ((100 - semi_optimal_frame_SR)/100) * orginal_frame_size + wasted_bits_by_delta_sel;
    optimal_frame_SR = 100 * (orginal_frame_size  - compressed_frame_size_opt)/(  orginal_frame_size);
    semi_optimal_frame_SR = 100 * (orginal_frame_size - compressed_frame_size_semi)/(orginal_frame_size);
    if(strcmp(METHOD,'OPT'))
         fprintf('%.2f\t  %.2f\t %.2f\t  %.2f\t\n',optimal_frame_SR,delta0_ratio_opt,delta1_ratio_opt,delta3_ratio_opt);

    elseif(strcmp(METHOD,'SEMI'))
         fprintf('%.2f\t  %.2f\t %.2f\t  %.2f\t\n',semi_optimal_frame_SR,delta0_ratio_semi_opt,delta1_ratio_semi_opt,delta3_ratio_semi_opt);

    end    



end

end


