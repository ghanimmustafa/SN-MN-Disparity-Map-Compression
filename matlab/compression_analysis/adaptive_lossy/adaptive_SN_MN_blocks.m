
% resolution_array = zeros(10,2);
processed_maps(1).DMs_name = Census_DMs;
processed_maps(2).DMs_name = Rank_DMs;
processed_maps(3).DMs_name = CRT_DMs;
reduction_factor = 1;
thres = 0;
encoders_n = 2;
SN_header_bits = 1;
MN_header_bits = 2;
averages_file = fopen('adaptive_SN_MN_averages_full_integer_GTs.txt','w');
fprintf(averages_file,'Blocks Number\t Avg.Space.Savings\t  SN-selection\t MN-selection\t\n');    

for blocks_n = [1,2,4,8,16,32,64,128,255,512,1024,2048]
    fprintf('Current block number = %i\n',blocks_n);
    best_space_savings = zeros(length(GTs),3);%zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),3);
    ss_index = 0;

   %for group_index = 1:3
   %     fprintf('Processed group = %i\n',group_index);
        for dm = 1:length(GTs)%length(processed_maps(group_index).DMs_name) 

%             if(median_filter)
%                 processed_map = single(processed_maps(group_index).DMs_name(dm).md);
%             else
%                 processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
%             end
              processed_map = GTs{dm};




                % MSB level qunatization: 
                processed_map = floor(processed_map/reduction_factor);
                [HEIGHT,WIDTH] = size(processed_map);
                orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));

                slice_length = floor(WIDTH/blocks_n);
                line_SRs = zeros(HEIGHT,blocks_n,encoders_n);
                optimal_line_SRs = zeros(HEIGHT,blocks_n,encoders_n);
                for row = 1:HEIGHT
                    block_index = 0;
                    MN_consumed_bits = 0;
                    SN_consumed_bits = 0;                   
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
                        elseif(column == WIDTH)
                            top_right_n = NaN;

                        else
                            top_n = processed_map(row-1,column);
                            top_right_n = processed_map(row-1,column+1);

                        end


                        current = processed_map(row,column);



                        diff_l = (abs(left_n - current));
                        diff_t = (abs(top_n - current));
                        diff_tr = (abs(top_right_n - current));
                        if(row == 1)

                            if(diff_l <= thres)
                                SN_consumed_bits = SN_consumed_bits + SN_header_bits;
                            else
                                SN_consumed_bits = SN_consumed_bits + SN_header_bits + orginal_bits;
                            end
                            if(column == WIDTH)
                               SN_ss = 100 *  (1 - (SN_consumed_bits)/(orginal_bits * WIDTH)) ; 
                               line_SRs(row,:,1) = SN_ss; 
                            end
                        else
                            
                             if(diff_l <= thres)
                                SN_consumed_bits = SN_consumed_bits + SN_header_bits;
                            else
                                SN_consumed_bits = SN_consumed_bits + SN_header_bits + orginal_bits;
                             end                           

                             if((diff_l <= thres) || (diff_t <= thres) || (diff_tr <= thres))
                                MN_consumed_bits = MN_consumed_bits + MN_header_bits;
                            else
                                MN_consumed_bits = MN_consumed_bits + MN_header_bits + orginal_bits;
                            end                              
                            %% Calculate space savings in blocks
                            if(((mod(column,slice_length) == 0) || (column == WIDTH)) && (block_index <=blocks_n))


                                if((block_index == (blocks_n) && (column == WIDTH) ))
    %                                 if(row == 1)
    %                                     fprintf('buraya girdi !! \n');
    % 
    %                                 end
                                      remaining_pixels = WIDTH - ((blocks_n) * slice_length);
                                      combined_last_pixels = remaining_pixels + slice_length;
                                      SN_ss = 100 *  (1 - (SN_consumed_bits + 1)/(orginal_bits * combined_last_pixels)) ;
                                      MN_ss = 100 *  (1 - (MN_consumed_bits + 1)/(orginal_bits * combined_last_pixels)) ;
                                      SN_consumed_bits = 0;
                                      MN_consumed_bits = 0;                               
                                      line_SRs(row,block_index,1) = SN_ss;
                                      line_SRs(row,block_index,2) = MN_ss;

                                elseif(block_index < blocks_n)

                                    block_index = block_index + 1;

                                    SN_ss = 100 *  (1 - (SN_consumed_bits + 1)/(orginal_bits * slice_length)) ;
                                    MN_ss = 100 *  (1 - (MN_consumed_bits + 1)/(orginal_bits * slice_length)) ;
                                    line_SRs(row,block_index,1) = SN_ss;
                                    line_SRs(row,block_index,2) = MN_ss;
                                   
                                   
                                      if((block_index ~= blocks_n))
                                          SN_consumed_bits = 0;
                                          MN_consumed_bits = 0;
                                      end

                                end                       

                            end
                        end

                    end
                
                end
              %     cuurent_space_saving = 1 - (consumed_bits/(WIDTH * HEIGHT * (orginal_bits + log2(reduction_factor))));
                    %fprintf('%.2f\n',100 * cuurent_space_saving);
                  [optimal_line_SRs(:,:,1),optimal_line_SRs(:,:,2)] = max(line_SRs,[],3);
                    ss_index = ss_index + 1;
                  best_space_savings(ss_index,1) = sum(sum(optimal_line_SRs(:,:,1))/HEIGHT)/blocks_n;
                  best_space_savings(ss_index,2) = 100 * sum(sum(optimal_line_SRs(:,:,2) == 1)/HEIGHT)/blocks_n;
                  best_space_savings(ss_index,3) = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 2)/HEIGHT)/blocks_n;

        end
            

   %end
      averages =  mean(best_space_savings,1);
     fprintf('Average space savings for block %i = %.2f\n',blocks_n,averages(1));
     fprintf('Average SN selection ratio for block %i = %.2f\n',blocks_n,averages(2));
     fprintf('Average MN selection ratio for block %i = %.2f\n',blocks_n,averages(3));
     fprintf(averages_file,'%i\t %.2f\t  %.2f\t %.2f\t\n',blocks_n, averages(1),averages(2),averages(3));

end
fclose('all');