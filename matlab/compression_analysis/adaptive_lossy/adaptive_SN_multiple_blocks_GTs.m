%% Applying optimal delta for each line ( using SN)



detailed_file = fopen('adaptive_SN_binary_delta_opt_GTs_one_bit_frac.txt','w');
averages_file = fopen('adaptive_SN_binary_delta_opt_GTs_one_bit_frac_averages.txt','w');

METHOD = 'OPT';
DELTAS = [0,0.5,1];
fprintf(averages_file,'Blocks Number\t Avg.Space.Savings\t  Delta=%.2f\t Delta=%.2f\t Delta=%.2f\t\n',DELTAS(1),DELTAS(2),DELTAS(3));    

for blocks_n = [1,2,4,8,16,32,64,128,256,512,1024]
    space_savings = zeros(length(GTs),length(DELTAS) + 1);
    ss_index = 0;
    fprintf('For BLOCKS NUMBER = %i PER LINE..\n',blocks_n);
    fprintf(detailed_file,'For BLOCKS NUMBER = %i PER LINE..\n',blocks_n);
        for dm = 1:length(GTs) 


           processed_map = GTs{dm};



           orginal_bits = (length(de2bi(max(max(floor(processed_map))),'left-msb'))) + fraction_bits;

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

                        current = processed_map(row,column);


                       % if((abs(left_n - current) <= thres)) %% for integer based
                       % comparsions
                        diff = abs(left_n - current);

                       if( ( diff <= thres) )

                              cnt = cnt + 1;
                       end


                        if( thres == 0)
                             header_bits = 1;

                        elseif ( thres == 1)
                             header_bits = 2;

                         elseif ( thres == 0.5)
                             header_bits = 2;

                        end
                        
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
                 wasted_bits_by_delta_sel = HEIGHT * blocks_n;%(length(de2bi(max(DELTAS),'left-msb'))) * HEIGHT * blocks_n;
                 orginal_frame_size = orginal_bits * WIDTH * HEIGHT;

               
             if(strcmp(METHOD,'OPT'))
                


                delta0_ratio_opt = 100 * sum(sum(optimal_line_SRs(:,:,2) == 1)/HEIGHT)/blocks_n;
                delta1_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 2)/HEIGHT)/blocks_n;
            %    delta3_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 3)/HEIGHT)/blocks_n;
             %   delta7_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 4)/HEIGHT)/blocks_n;  
              %  delta15_ratio_opt = 100 *  sum(sum(optimal_line_SRs(:,:,2) == 5)/HEIGHT)/blocks_n;  
                
                compressed_frame_size_opt = ((100 - optimal_frame_SR)/100) * orginal_frame_size + wasted_bits_by_delta_sel;
                optimal_frame_SR = 100 * (orginal_frame_size  - compressed_frame_size_opt)/(  orginal_frame_size);                
 
                 space_savings(ss_index,1) = optimal_frame_SR;
                 space_savings(ss_index,2:end) = [delta0_ratio_opt,delta1_ratio_opt];                
                fprintf(detailed_file,'%.2f\t %.2f\t  %.2f\t  \n',optimal_frame_SR,delta0_ratio_opt,delta1_ratio_opt);

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
        averages = mean(space_savings);
        fprintf('Avg. Space Savings and Selection Ratios = \n');
        fprintf('%.2f\t  %.2f\t %.2f\t\n',averages(1),averages(2),averages(3));
        fprintf(averages_file,'%i\t %.2f\t  %.2f\t %.2f\t \n',blocks_n, averages(1),averages(2),averages(3));

end

    

fclose('all');

