
% resolution_array = zeros(10,2);
processed_maps(1).DMs_name = Census_DMs;
processed_maps(2).DMs_name = Rank_DMs;
processed_maps(3).DMs_name = CRT_DMs;
reduction_factor = 1;
deltas = [0,1,3];
BUFFER_EVEN_INDEX = false; %% Storing only even-indices in the buffer ( starting from 0)
for thres = [0,1,3]
    ss_index = 0;
    space_savings =    zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1); % zeros(length(GTs),1); 

   for group_index = 1:3
        fprintf('Processed group = %i\n',group_index);
        for dm = 1: length(processed_maps(group_index).DMs_name)  % 1:length(GTs) 

            if(median_filter)
                processed_map = single(processed_maps(group_index).DMs_name(dm).md);
            else
                processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
            end



                % MSB level qunatization: 
              %  processed_map = GTs{dm};
            %    processed_map = floor(processed_map/reduction_factor);
                [HEIGHT,WIDTH] = size(processed_map);
                orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
                orginal_bits = double(orginal_bits);
                % orginal_bits = ceil(log2(max(max(processed_map)))) + fraction_bits;
                consumed_bits = 0;
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
                        top_right_right_n = NaN;
                        top_right_right_right_n = NaN;
                    else
                        if(column == 1)
                            top_left_n = NaN;
                        else
                            top_left_n = processed_map(row-1,column-1);
                        end
                        if(column == WIDTH)
                            top_right_n = NaN;
                        else
                            top_right_n = processed_map(row-1,column+1);
                        end
                        
                        if(column >= (WIDTH-2))
                            top_right_right_n = NaN;
                        else
                            top_right_right_n = processed_map(row-1,column+2);
                        end
                        if(column >= (WIDTH-3))
                            top_right_right_right_n = NaN;
                        else
                            top_right_right_right_n = processed_map(row-1,column+3);
                        end                       
                        top_n = processed_map(row-1,column);
                        
                    end


                    current = processed_map(row,column);
                    

                    
                    diff_l = (abs(left_n - current));
                    if(BUFFER_EVEN_INDEX)
                        %% If the current pixel index is even ( starting with 0), compare it with top and top-right-right pixels
                        if(mod(column-1,2) == 0)

                            diff_t = (abs(top_n - current));
                            diff_tr = (abs(top_right_right_n - current));
                        else
                        %% If the current pixel index is odd ( starting with 0), compare it with top-left and top-right pixels
                            diff_t = (abs(top_left_n - current));
                            diff_tr = (abs(top_right_n - current));                      

                        end
                        
                    else
                         %% If the current pixel index is even ( starting with 0), compare it with top-right and top-right-right-right pixels
                        if(mod(column-1,2) == 0)

                            diff_t = (abs(top_right_n - current));
                            diff_tr = (abs(top_right_right_n - current));
                        else
                        %% If the current pixel index is odd ( starting with 0), compare it with top and top-right-right pixels
                            diff_t = (abs(top_n - current));
                            diff_tr = (abs(top_right_right_n - current));                      

                        end                       
                        
                    end   

                   
                    if(thres == 0)
                        header_bits = 2;

                    elseif( thres == 1)
                        header_bits = 4;

                    else
                         header_bits = 5;

                    end                  
                    if((diff_l <= thres) || (diff_t <= thres) || (diff_tr <= thres)) %%  any(diff_l == deltas) || any(diff_t == deltas) || any(diff_tr == deltas)
               
                        consumed_bits = consumed_bits + header_bits;
                    else
                        
                        consumed_bits = consumed_bits + header_bits + orginal_bits;


                       % fprintf('left_n = %.2f, current = %.2f\n',left_n,current);

                    end





                    end
                
                end
                    %coverage_ratio = cnt/length(image_vector);
                   % cuurent_space_saving = (orginal_bits - (coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( header_bits + orginal_bits)))/orginal_bits;
                   cuurent_space_saving = 1 - (consumed_bits/(WIDTH * HEIGHT * (orginal_bits + log2(reduction_factor))));
                    %fprintf('%.2f\n',100 * cuurent_space_saving);
                    ss_index = ss_index + 1;
                    space_savings(ss_index) = cuurent_space_saving;

        end
            
        
   end
     
    fprintf('Average space savings for thres %i = %.2f\n',thres,100 * mean(space_savings));
        
end