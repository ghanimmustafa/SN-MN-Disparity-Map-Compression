
% resolution_array = zeros(10,2);
processed_maps(1).DMs_name = Rank_DMs;
processed_maps(2).DMs_name = CRT_DMs;
processed_maps(3).DMs_name = Census_DMs;
Q = 1; %quantization factor
deltas = [0,1,3];
USE_JPEG_LS_MPO = false;
fprintf('Median filter is : %i \n',median_filter);
average_space_savings = zeros(1,64);

%for FILTER_SIZE = [3,5,7,9]
for thres = 0:63
    ss_index = 0; %zeros(length(GTs),1);  
    space_savings =   zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1); 

   for group_index = 1:3
        %fprintf('delta = %i, Processed group = %i\n',thres,group_index);
        for dm = 1:length(processed_maps(group_index).DMs_name)  %length(GTs) %

            if(median_filter)
                processed_map = single(processed_maps(group_index).DMs_name(dm).md);
            else
                processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
            end
                %processed_map = non_padded_median_filters(processed_map,FILTER_SIZE,FILTER_SIZE);
        %for dm=1:length(GTs)
            

                % MSB level qunatization: 
              %  processed_map = GTs{dm};
                %processed_map = floor(processed_map/Q);
                [HEIGHT,WIDTH] = size(processed_map);
                orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
                orginal_bits = double(orginal_bits);
           %     orginal_bits = ceil(log2(max(max(processed_map)))) + fraction_bits;
                consumed_bits = 0;
                cnt = 0;
                for row = 1:HEIGHT
                    for column = 1: WIDTH

                    if((row == 1) && (column == 1))
                        left_n = NaN;
                    elseif( row > 1 && column == 1)
                        left_n = processed_map(row-1,WIDTH);
                    else
                        left_n = processed_map(row,column - 1);
                    end
                    if(row == 1)
                        top_n = NaN;
                        top_right_n = NaN;
                        top_left_n = NaN;
                        
                    elseif(column == WIDTH && row > 1)
                        top_right_n = NaN;
                        top_n = processed_map(row-1,column);
                        top_left_n = processed_map(row-1,column-1);
                       
                    elseif(column == 1)
                        top_left_n = NaN;               
                    else
                        
                        top_n = processed_map(row-1,column);
                        top_right_n = processed_map(row-1,column+1);
                        top_left_n = processed_map(row-1,column-1);
                        
                    end


                    current = processed_map(row,column);
                    


                    diff_l = (abs(left_n - current));
                    diff_t = (abs(top_n - current));
                    if(USE_JPEG_LS_MPO)
                        add_sub_neighbour  = left_n + top_n - top_left_n ;
                        diff_tr = (abs(add_sub_neighbour - current));
                    else
                        diff_tr = abs(top_right_n - current);
                    end                   
                    if(thres == 0)
                        header_bits = 2;

                    else 
                        header_bits = ceil(log2(thres+1)) + 3;

                    end                
                    if((diff_l <= thres) || (diff_t <= thres) || (diff_tr <= thres)) %%  any(diff_l == deltas) || any(diff_t == deltas) || any(diff_tr == deltas)
                        cnt = cnt + 1;
                        consumed_bits = consumed_bits + header_bits;
                    else
                        
                        consumed_bits = consumed_bits + header_bits + orginal_bits;


                       % fprintf('left_n = %.2f, current = %.2f\n',left_n,current);

                    end





                    end
                
                end
                 %   coverage_ratio = cnt/(WIDTH * HEIGHT);
                 %   cuurent_space_saving = (orginal_bits - (coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( header_bits + orginal_bits)))/orginal_bits;
                    cuurent_space_saving = 1 - (consumed_bits/(WIDTH * HEIGHT * (orginal_bits + log2(Q) ))); % log2(reduction_factor)

                    %fprintf('%f\n',100 * cuurent_space_saving);
                    ss_index = ss_index + 1;
                    space_savings(ss_index) = (cuurent_space_saving);

        %end
            

    %end
    % fprintf('Average space savings for thres %i = %.2f\n',thres,100 * mean(space_savings));
    
   
        end

   end
    fprintf('%.2f\n',100 * mean(space_savings));
    average_space_savings(thres+1) = round(100 * mean(space_savings),2);   

end  