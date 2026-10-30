%% Applying optimal delta for each line ( using SN)


METHOD = 'SEMI';
 %   fprintf(strcat('Current DMs are',getVarName(processed_maps))) 
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

       % processed_map = single(Rank_DMs(dm).disparity_map);


       orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));

        %% For GT with subpixel
       % max_integer_bits = ceil(log2(max(max(GTs{dm}))));

      %  orginal_bits = max_integer_bits + fraction_bits;
        [HEIGHT,WIDTH] = size(processed_map);
       %  fprintf('%i\n',orginal_bits);
        line_SRs = zeros(HEIGHT,3);
        optimal_line_SRs = zeros(HEIGHT,2);   
        for row=1:HEIGHT
            index = 0;
            for thres = [0,1,3]
                cnt = 0;
                index = index + 1;
                for column =1:WIDTH
                    if(column == 1)
                        left_n = NaN;
                    else
                        left_n = processed_map(row,column-1);
                    end
                    current = processed_map(row,column);


                   % if((abs(left_n - current) <= thres)) %% for integer based
                   % comparsions


                   if( (abs(left_n - current) <= thres))

                          cnt = cnt + 1;
                    end
                    coverage_ratio_norm =  cnt/((WIDTH));
                    if( thres == 0)
                         header_bits = 1;

                    elseif ( thres == 1)
                         header_bits = 2;

                     elseif ( thres == 3)
                         header_bits = 3;

                    end
                    compression_ratio = 100 * (orginal_bits - (coverage_ratio_norm * header_bits + ( 1 - coverage_ratio_norm) * ( header_bits + orginal_bits)))/orginal_bits;


                end
                    line_SRs(row,index) = compression_ratio ;


            end   

        end

        [optimal_line_SRs(:,1),optimal_line_SRs(:,2)] = max(line_SRs,[],2);

        optimal_frame_SR = sum(optimal_line_SRs(:,1))/HEIGHT;

        semi_optimal_SRs = last_line_delta_same(line_SRs,optimal_line_SRs,-1);

        semi_optimal_frame_SR = sum(semi_optimal_SRs(:,1))/HEIGHT;

        delta0_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 1)/HEIGHT;
        delta1_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 2)/HEIGHT;
        delta3_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 3)/HEIGHT;

        delta0_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 1)/HEIGHT;
        delta1_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 2)/HEIGHT;
        delta3_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 3)/HEIGHT;    
      %  delta7_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 4)/HEIGHT;  
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
        %saving_ratios = [semi_optimal_frame_SR,saving_ratios];


    end

end
    

    %fprintf('Mean SR = %.2f \n',mean(saving_ratios));




