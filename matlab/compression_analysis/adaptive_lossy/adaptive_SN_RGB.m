%% Applying optimal delta for each line ( using SN)
this_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(fileparts(this_dir)));
if exist('DATASET_ROOT', 'var') && ~isempty(DATASET_ROOT)
    path_to_read = DATASET_ROOT;
else
    path_to_read = fullfile(repo_root, 'data');
end
disp_dirs = dir(fullfile(path_to_read, '*_disp'));
disp_dirs = disp_dirs([disp_dirs.isdir]);

mean_RGB_bbp_opt = zeros(length(RGB_images),1);
mean_RGB_bbp_semi_opt = zeros(length(RGB_images),1);

thres_array = [0,1,3,7,15,31,63];
mean_selected_opt_deltas = zeros(length(RGB_images),length(thres_array));
mean_selected_semi_opt_deltas = zeros(length(RGB_images),length(thres_array));
header_bits = zeros(1,length(thres_array));
for thres_index = 1:length(thres_array)
    if(thres_array(thres_index) == 0)
        header_bits(thres_index) = 0;
    else
        header_bits(thres_index) = length(de2bi(thres_array(thres_index))) + 1;
        
    end
    
    
    
end
for dm = 1:length(RGB_images)

    processed_map = single(RGB_images{dm});
    fprintf(imagefiles(dm).name);
    fprintf('\t is being processed ..\n');


    orginal_bits = 8;

    %% For GT with subpixel
   % max_integer_bits = ceil(log2(max(max(GTs{dm}))));

  %  orginal_bits = max_integer_bits + fraction_bits;
    [HEIGHT,WIDTH,CHANNEL] = size(processed_map);
   %  fprintf('%i\n',orginal_bits);

    bbp_opt = zeros(1,3);
    bbp_semi_opt = zeros(1,3);
    delta_opt = zeros(CHANNEL,length(thres_array));
    delta_semi_opt = zeros(CHANNEL,length(thres_array));
   
    for ch =1:CHANNEL
        line_SRs = zeros(HEIGHT,length(thres_array));
        optimal_line_SRs = zeros(HEIGHT,2);    
        for row=1:HEIGHT
            index = 0;
%             if(mod(row,100) == 0) 
%                fprintf('%i many lines are processed .. \n',row); 
%                 
%             end
            for thres_index = 1:length(thres_array) 
                cnt = 0;
                index = index + 1;
                for column =2:WIDTH

                    left_n = processed_map(row,column-1,ch);
                    current = processed_map(row,column,ch);


                   % if((abs(left_n - current) <= thres)) %% for integer based
                   % comparsions

                    
                    
                   if(   abs(left_n - current) <= thres_array(thres_index))

                          cnt = cnt + 1;
                    end
                    coverage_ratio_norm =  cnt/((WIDTH-1));
                    
                    header_bits_number = header_bits(thres_index);
                    compression_ratio = 100 * (orginal_bits - (coverage_ratio_norm * header_bits_number + ( 1 - coverage_ratio_norm) * ( header_bits_number + orginal_bits)))/orginal_bits;


                end
                    line_SRs(row,index) = compression_ratio;


            end   

        end

        [optimal_line_SRs(:,1),optimal_line_SRs(:,2)] = max(line_SRs,[],2);

        optimal_frame_SR = sum(optimal_line_SRs(:,1))/HEIGHT;

        semi_optimal_SRs = last_line_delta_same(line_SRs,optimal_line_SRs);

        semi_optimal_frame_SR = sum(semi_optimal_SRs(:,1))/HEIGHT;

%         delta0_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 1)/HEIGHT;
%         delta1_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 2)/HEIGHT;
%         delta3_ratio_semi_opt = 100 * sum(semi_optimal_SRs(:,2) == 3)/HEIGHT;
% 
%         delta0_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 1)/HEIGHT;
%         delta1_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 2)/HEIGHT;
%         delta3_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 3)/HEIGHT;    
%         delta7_ratio_opt = 100 * sum(optimal_line_SRs(:,2) == 4)/HEIGHT;


        bbp_opt(ch)  = orginal_bits - optimal_frame_SR*orginal_bits/100;
        bbp_semi_opt(ch) = orginal_bits - semi_optimal_frame_SR*orginal_bits/100;
        for thres_index = 1:length(thres_array) 
            
            delta_opt(ch,thres_index) = 100 * sum(optimal_line_SRs(:,2) == thres_index)/HEIGHT;
            delta_semi_opt(ch,thres_index) = 100 * sum(semi_optimal_SRs(:,2) == thres_index)/HEIGHT;        
        end
    end
    mean_RGB_bbp_opt(dm) = mean(bbp_opt);
    mean_RGB_bbp_semi_opt(dm) = mean(bbp_semi_opt);
    mean_selected_opt_deltas(dm,:) = mean(delta_opt,1);
    mean_selected_semi_opt_deltas (dm,:) = mean(delta_semi_opt,1); 
    %fprintf('%.2f\t  %.2f\t %.2f\t  %.2f\t %.2f\t  \n',mean_RGB_bbp,delta0_ratio_opt,delta1_ratio_opt,delta3_ratio_opt,delta7_ratio_opt);



end

fprintf('Adaptive Optimal bbp for SN = %.2f\n',mean(mean_RGB_bbp_opt));
fprintf('Adaptive Optimal Selections  SN = \n',mean(mean_selected_opt_deltas,1));

fprintf('Adaptive Semi Optimal bbp for SN = %.2f\n',mean(mean_RGB_bbp_semi_opt));
fprintf('Adaptive  Semi Optimal Selections  SN = \n',mean(mean_selected_semi_opt_deltas,1));
