
% resolution_array = zeros(10,2);

reduction_factor = 1;
deltas = [0,1,3];
BUFFER_ONLY_EVEN_ROWS = true;
for thres = [0,1,3]
    ss_index = 0;
    space_savings =  zeros(length(GTs),1); 

        fprintf('Processed group = %i\n',group_index);
        for dm =1:length(GTs) 

                % MSB level qunatization: 
              %  processed_map = GTs{dm};
            %    processed_map = floor(processed_map/reduction_factor);
                processed_map = GTs{dm};
              
                [HEIGHT,WIDTH] = size(processed_map);
                orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
                orginal_bits = double(orginal_bits);
                % orginal_bits = ceil(log2(max(max(processed_map)))) + fraction_bits;
                consumed_bits = 0;
                for row = 1:HEIGHT
                    QLB_index = 0;
                    if(row > 1)
                        if(BUFFER_ONLY_EVEN_ROWS)
                            if(mod(row-1,2) == 0) % for 0-based index system. (even)
                                line_buffer = processed_map(row-2,:);
                               
                            else
                                line_buffer = processed_map(row-1,:);
                            end                    
                        else
                            line_buffer = processed_map(row-1,:);
                        end
                         quarter_line_buffer = line_buffer(1:4:end);      
                    end
                    for column = 1: WIDTH
                        if(mod(column-1,4) == 0)
                            QLB_index = QLB_index + 1;
                        end

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
                    else

                        if(QLB_index == length(quarter_line_buffer))
                            top_right_n = NaN;
                        else
                                top_right_n = quarter_line_buffer(QLB_index+1);  
                        end
                        top_n = quarter_line_buffer(QLB_index);  
             
                        
                        
                    end


                    current = processed_map(row,column);
                    

                    
                    diff_l = (abs(left_n - current));
                    diff_t = (abs(top_n - current));
                    diff_tr = (abs(top_right_n - current));
      
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
            
         fprintf('Average space savings for thres %i = %.2f\n',thres,100 * mean(space_savings));

   end
     
        
