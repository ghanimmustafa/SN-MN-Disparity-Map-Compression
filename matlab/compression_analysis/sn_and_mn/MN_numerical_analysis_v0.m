
%% This code omits the first and last column of each row in the frame. 

processed_maps(1).DMs_name = Rank_DMs;
processed_maps(2).DMs_name = CRT_DMs;
processed_maps(3).DMs_name = Census_DMs;
fprintf('Median filter is : %i \n',median_filter);

for thres = [0,1,3]


    ss_index = 0;
    space_savings =   zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1); % zeros(length(GTs),1); 

   for group_index = 1:3
        fprintf('delta = %i, Processed group = %i\n',thres,group_index);
        for dm = 1:length(processed_maps(group_index).DMs_name)  %length(GTs) %

            if(median_filter)
                processed_map = single(processed_maps(group_index).DMs_name(dm).md);
            else
                processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
            end




                % MSB level qunatization: 
             %   processed_map = GTs{dm};
            %    processed_map = floor(processed_map/reduction_factor);
                [row,col] = size(processed_map);
                orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
                %orginal_bits = int32(orginal_bits);
           %     orginal_bits = ceil(log2(max(max(processed_map)))) + fraction_bits;
                consumed_bits = 0;
                cnt = 0;  
        for i=2:row


            for j =2:col-1
                left_neighbour = processed_map(i,j-1);
                top_neighbour = processed_map(i-1,j);
                top_right_neighbour = processed_map(i-1,j+1);
                current_pixel_cost = processed_map(i,j);
                top_left_neighbour = processed_map(i-1,j-1); %% c
                add_sub_neighbour  = left_neighbour + top_neighbour - top_left_neighbour ; %% a + b - c


                diff1 = abs(current_pixel_cost - left_neighbour);
                diff2 = abs(current_pixel_cost - top_neighbour);
                diff3 = abs(current_pixel_cost - top_right_neighbour);
                %diff3 = abs(current_pixel_cost - add_sub_neighbour);

                %% ((diff1 <= thres)|| (diff2 <= thres) || (diff3 <= thres))
                % for floating-point
                % Diff1
                cond1 = (diff1 == thres)|| (diff1 == (thres-1)) || (diff1 == (thres-2)) || (diff1 == (thres-3));
                cond2 = (diff2 == thres)|| (diff2 == (thres-1)) || (diff2 == (thres-2)) || (diff2 == (thres-3));
                cond3 = (diff3 == thres)|| (diff3 == (thres-1)) || (diff3 == (thres-2)) || (diff3 == (thres-3));
                %diff <= thres) && ((floor(diff) == diff) || ( diff == thres)
                if((diff1 <= thres)|| (diff2 <= thres) || (diff3 <= thres))

                        cnt = cnt + 1;

                end
            end

        end
          coverage_ratio = (cnt/(row * (col-2)));
         if( thres == 0)
             header_bits = 2;

         elseif ( thres == 1)
             header_bits = 4;

         else
             header_bits = 5;

         end
         %compression_ratio = (orginal_bits - (norm_cov_r * header_bits + ( 1 - norm_cov_r) * ( header_bits + orginal_bits)))/orginal_bits;
         current_space_savings = (orginal_bits - (coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( header_bits + orginal_bits)))/orginal_bits;
         ss_index = ss_index + 1;
         space_savings(ss_index) =  current_space_savings;         

        end
   end
         fprintf('%.2f\n',100 * mean(space_savings));
end


