this_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(fileparts(this_dir)));
if exist('DATASET_ROOT', 'var') && ~isempty(DATASET_ROOT)
    path_to_read = DATASET_ROOT;
else
    path_to_read = fullfile(repo_root, 'data');
end
disp_dirs = dir(fullfile(path_to_read, '*_disp'));
disp_dirs = disp_dirs([disp_dirs.isdir]);
%processed_maps = CRT_DMs;
%orginal_bits = 8;
compression_ratios = [];
fraction_bits = 4;
for DMs_index = 1:3
    
    if(DMs_index == 1)
        DMs = Rank_DMs;
    elseif(DMs_index == 2)
        DMs = CRT_DMs;
    else
         DMs = Census_DMs;
    end
    fprintf('DMs of index %i are being processed .. \n',DMs_index);
    for thres = 3
        
        for img_index = 1:length(DMs)

    % ground_truth_path = strcat(path_to_read,'\',char(image_names(img_index)),'_disp');
    % ground_truth = pfmread(strcat(ground_truth_path,'\disp1.pfm'));
    % max_integer_bits = ceil(log2(max(max(round(ground_truth)))));
    % 
    % total_orginal_bits = max_integer_bits + fraction_bits;
    % ground_truth = fi(ground_truth,0,total_orginal_bits,fraction_bits);
    % ground_truth = ground_truth.data;
    % processed_map =  ground_truth; %processed_maps(img_index).md;


    processed_map = single(DMs(img_index).md);
    total_orginal_bits = 8;
    [row,col] = size(processed_map);


            cnt = 0;
            for i=2:row
                if (mod(i, 10) == 0)

                    %fprintf('Line %i is processed .\n', i); 
                end

                for j =2:col-1
                    left_neighbour = processed_map(i,j-1); %% a
                    top_neighbour = processed_map(i-1,j); %% b
                    top_left_neighbour = processed_map(i-1,j-1); %% c
                    top_right_neighbour = processed_map(i-1,j+1); %% d
                    add_sub_neighbour  = left_neighbour + top_neighbour - top_left_neighbour ; %% a + b - c
                    current_pixel_cost = processed_map(i,j);
                    diff1 = abs(current_pixel_cost - left_neighbour);
                    diff2 = abs(current_pixel_cost - top_neighbour);
                    diff3 = abs(current_pixel_cost - add_sub_neighbour);

                    %% ((diff1 <= thres)|| (diff2 <= thres) || (diff3 <= thres))
                    % for floating-point
                    % Diff1
                  %  cond1 = (diff1 == thres)|| (diff1 == (thres-1)) || (diff1 == (thres-2)) || (diff1 == (thres-3));
                   % cond2 = (diff2 == thres)|| (diff2 == (thres-1)) || (diff2 == (thres-2)) || (diff2 == (thres-3));
                   % cond3 = (diff3 == thres)|| (diff3 == (thres-1)) || (diff3 == (thres-2)) || (diff3 == (thres-3));

                   % if((cond1)|| (cond2) || (cond3)) %% for GT

                        %   cnt = cnt + 1;

                   % end

                  if((diff1 <= thres) || (diff2 <= thres) || (diff3 <= thres))
                      cnt = cnt + 1;

                  end
                end

            end
          % fprintf('position of  %i and %i is done .\n', i,j); 
              format long g  
              Ratio = round(100 * cnt/(row * (col-2)),2);
              norm_cov_r = Ratio/100;
              % fprintf('%.2f \n',Ratio);
              %fprintf('For Type-2 threshold %i, coverage ratio = %.2f\n' ,thres,Ratio);
             if( thres == 0)
                 header_bits = 2;

             elseif ( thres == 1)
                 header_bits = 4;

             else
                 header_bits = 5;

             end
             compression_ratio = 100 *((total_orginal_bits - (norm_cov_r * header_bits + ( 1 - norm_cov_r) * ( header_bits + total_orginal_bits)))/total_orginal_bits);
             fprintf('%.2f\n',compression_ratio);
            % fprintf('DELTA = %i : Compression Ratio =  %.2f \n',thres,100* compression_ratio);
            %fprintf('%.2f \n',100 * compression_ratio);  

           %  fprintf('%.2f \n',compression_ratio);



        %compression_ratios = [compression_ratios,compression_ratio];



        end
        %fprintf('Threshold = %i is done ..\n',thres);

     end    

%fprintf('Average compression ratio = %.2f \n',mean(compression_ratios))
end
   