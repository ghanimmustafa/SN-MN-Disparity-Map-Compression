%% Applying optimal delta for each line ( using SN)

processed_maps(1).DMs = Census_DMs;
processed_maps(1).name = 'Census_DMs';
processed_maps(2).DMs = Rank_DMs;
processed_maps(2).name = 'Rank_DMs';
processed_maps(3).DMs = CRT_DMs;
processed_maps(3).name = 'CRT_DMs';

detailed_file = fopen('adaptive_MN_binary_opt_filtered_all.txt','w');
averages_file = fopen('adaptive_MN_binary_opt_filtered_averages.txt','w');
fprintf(averages_file,'Blocks Number\t Avg.Space.Savings\t  Delta=0\t Delta=1 Delta=3\t\n');    

METHOD = 'OPT';
DELTAS = [0,1,3];

for blocks_n = [1,2,4,8,16,32,64,128,256,512,1024]
    space_savings = zeros(length(Census_DMs)+ length(Rank_DMs) + length(CRT_DMs),length(DELTAS) + 1);
    ss_index = 0;
    fprintf('For BLOCKS NUMBER = %i PER LINE..\n',blocks_n);
    fprintf(detailed_file,'For BLOCKS NUMBER = %i PER LINE..\n',blocks_n);
    for group_index = 1:3
        fprintf(detailed_file,strcat('Processed group : ',processed_maps(group_index).name,'\n'));
        for dm = 1:length(processed_maps(group_index).DMs) 


            if(median_filter)
                processed_map = single(processed_maps(group_index).DMs(dm).md);
            else
                processed_map = single(processed_maps(group_index).DMs(dm).disparity_map);
            end

           % processed_map = single(Rank_DMs(dm).disparity_map);


           orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));

            %% For GT with subpixel
           % max_integer_bits = ceil(log2(max(max(GTs{dm}))));
          %  orginal_bits = max_integer_bits + fraction_bits;
            [HEIGHT,WIDTH] = size(processed_map);
            slice_length = floor(WIDTH/blocks_n);

           %  fprintf('%i\n',orginal_bits);
            line_SRs = zeros(HEIGHT,blocks_n,length(DELTAS));
            optimal_line_SRs = zeros(HEIGHT,blocks_n,2);   
            for row=1:HEIGHT

                thres_index = 0;

                for thres = DELTAS
                    cnt = 0;
                    thres_index = thres_index + 1;
                    block_index = 0;
                    flag = 0;
                    for column =1:WIDTH

                        if((column == 1) && (row == 1))
                            left_n = NaN;
                        elseif ((column == 1) && (row > 1))
                                
                            left_n = processed_map(row-1,WIDTH);
                            
                        else
                            left_n = processed_map(row,column-1);
                        end
                        if(row == 1)
                            top_right_n = NaN;
                            top_n = NaN;
                        elseif(column == WIDTH && row > 1)
                            top_right_n = NaN;
                            top_n = processed_map(row-1,column);
                        else
                            
                            top_right_n = processed_map(row-1,column+1);
                            top_n = processed_map(row-1,column);
                        end
                        

                        current = processed_map(row,column);

                        diff1 = abs(current - left_n);
                        diff2 = abs(current - top_n);
                        diff3 = abs(current - top_right_n);
                       % if((abs(left_n - current) <= thres)) %% for integer based
                       % comparsions


                       if((diff1 <= thres)|| (diff2 <= thres) || (diff3 <= thres))

                              cnt = cnt + 1;
                       end


                        if( thres == 0)
                             header_bits = 2;

                        elseif ( thres == 1)
                             header_bits = 4;
                        elseif ( thres == 3)
                             header_bits = 5;    
                             
                             
                        end

%                          elseif ( thres == 3)
%                              header_bits = 5;
% 
%                         end
                 %        elseif ( thres == 7)
                  %           header_bits = 4;

                   %     end
                        
                        if(((mod(column,slice_length) == 0) || (column == WIDTH)) && (block_index <=blocks_n))


                            if((block_index == (blocks_n) && (column == WIDTH) ))
%                                 if(row == 1)
%                                     fprintf('buraya girdi !! \n');
% 
%                                 end
                                  remaining_pixels = WIDTH - ((blocks_n) * slice_length);
                                  combined_last_pixels = remaining_pixels + slice_length;
                                  coverage_ratio_norm =  cnt/((combined_last_pixels));
                                  compression_ratio = 100 * (orginal_bits - (coverage_ratio_norm * header_bits + ( 1 - coverage_ratio_norm) * ( header_bits + orginal_bits)))/orginal_bits;
                                  cnt = 0;
                                  line_SRs(row,block_index,thres_index) = compression_ratio ;                                


                            elseif(block_index < blocks_n)

                                block_index = block_index + 1;
                                coverage_ratio_norm =  cnt/((slice_length));
                                compression_ratio = 100 * (orginal_bits - (coverage_ratio_norm * header_bits + ( 1 - coverage_ratio_norm) * ( header_bits + orginal_bits)))/orginal_bits;
                            %    if(flag == 0)
                                  if((block_index ~= blocks_n))
                                      cnt = 0;
                                  end

                              %  end
                                line_SRs(row,block_index,thres_index) = compression_ratio ;


                            end




                        end


                    end



                end   

            end
                ss_index = ss_index + 1;
                
                [optimal_line_SRs(:,:,1),optimal_line_SRs(:,:,2)] = max(line_SRs,[],3);
                optimal_frame_SR = sum(sum(optimal_line_SRs(:,:,1))/HEIGHT)/blocks_n; 
                 wasted_bits_by_delta_sel = (length(de2bi(max(DELTAS),'left-msb'))) * HEIGHT * blocks_n;
               
             if(strcmp(METHOD,'OPT'))
                


                delta0_ratio_opt = 100 * sum(sum(optimal_line_SRs(:,:,2) == 1)/HEIGHT)/blocks_n;
                delta1_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 2)/HEIGHT)/blocks_n;
                delta3_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 3)/HEIGHT)/blocks_n;
               % delta7_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 4)/HEIGHT)/blocks_n;              
                orginal_frame_size = orginal_bits * WIDTH * HEIGHT;
                compressed_frame_size_opt = ((100 - optimal_frame_SR)/100) * orginal_frame_size + wasted_bits_by_delta_sel;
                optimal_frame_SR = 100 * (orginal_frame_size  - compressed_frame_size_opt)/(  orginal_frame_size);                
 
                 space_savings(ss_index,1) = optimal_frame_SR;
                 space_savings(ss_index,2:end) = [delta0_ratio_opt,delta1_ratio_opt,delta3_ratio_opt];                
                fprintf(detailed_file,'%.2f\t %.2f\t  %.2f\t  %.2f\t\n',optimal_frame_SR,delta0_ratio_opt,delta1_ratio_opt,delta3_ratio_opt);

            elseif(strcmp(METHOD,'SEMI'))

                semi_optimal_SRs = last_line_delta_same(line_SRs,optimal_line_SRs,blocks_n);

                semi_optimal_frame_SR = sum(sum(semi_optimal_SRs(:,:,1))/HEIGHT)/blocks_n; 
                delta0_ratio_semi_opt = 100 * sum(sum(semi_optimal_SRs(:,:,2) == 1)/HEIGHT)/blocks_n;
                delta1_ratio_semi_opt = 100 *  sum(sum(semi_optimal_SRs(:,:,2) == 2)/HEIGHT)/blocks_n;
             %   delta3_ratio_semi_opt = 100 *  sum(sum(semi_optimal_SRs(:,:,2) == 3)/HEIGHT)/blocks_n;
                compressed_frame_size_semi = ((100 - semi_optimal_frame_SR)/100) * orginal_frame_size + wasted_bits_by_delta_sel;
                semi_optimal_frame_SR = 100 * (orginal_frame_size - compressed_frame_size_semi)/(orginal_frame_size);

                space_savings(ss_index,1) = semi_optimal_frame_SR;
                space_savings(ss_index,2:end) = [delta0_ratio_semi_opt,delta1_ratio_semi_opt];
                fprintf(detailed_file,'%.2f\t  %.2f\t %.2f\t\n',semi_optimal_frame_SR,delta0_ratio_semi_opt,delta1_ratio_semi_opt);
            end
         end


    end
    averages = mean(space_savings);
    fprintf('Avg. Space Savings and Selection Ratios = \n');
    fprintf('%.2f\t  %.2f\t %.2f\t %.2f\t\n',averages(1),averages(2),averages(3),averages(4));
    fprintf(averages_file,'%i\t %.2f\t  %.2f\t %.2f\t %.2f\t\n',blocks_n, averages(1),averages(2),averages(3),averages(4));
    
end
fclose(detailed_file);
fclose(averages_file);
fclose('all');

