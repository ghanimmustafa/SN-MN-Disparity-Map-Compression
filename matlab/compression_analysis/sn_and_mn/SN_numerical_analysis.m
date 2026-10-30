
% resolution_array = zeros(10,2);
processed_maps(1).DMs_name = Rank_DMs;
processed_maps(2).DMs_name = CRT_DMs;
processed_maps(3).DMs_name = Census_DMs;
Q = 1; %quantization factor
%deltas = [0,1,3];
FILTER_SIZE = 7;
fprintf('Median filter is : %i \n',median_filter);
%for Q = [1,2,4,8,16,32,64]
average_space_savings = zeros(1,64);
for thres = 0:63
    ss_index = 0;
   % space_savings = zeros(length(Census_DMs) + length(Rank_DMs) + length(CRT_DMs),1); % zeros(length(GTs),1);
    space_savings  =  zeros(length(GTs),1);
    %for group_index = 1:3
        %fprintf('delta = %i, Processed group = %i\n',thres,group_index);
        for dm = 1:length(GTs)% length(processed_maps(group_index).DMs_name) %

           % if(median_filter)
           %     processed_map = single(processed_maps(group_index).DMs_name(dm).md);
           % else
           %     processed_map = single(processed_maps(group_index).DMs_name(dm).disparity_map);
           % end
                processed_map = GTs{dm};

                %processed_map = non_padded_median_filters(processed_map,FILTER_SIZE,FILTER_SIZE);

                % MSB level qunatization: 
                %processed_map = floor(processed_map/Q);
                
                image_vector = reshape(processed_map',1,numel(processed_map))';
                orginal_bits = ceil(log2(max(max(processed_map)))) ;%+ fraction_bits;
                orginal_bits = double(orginal_bits); %% this is very important, otherwise calculations would be incorrect for consumed_bits
           %     fprintf('orginal_bits = %i\n',orginal_bits);
                cnt = 0;
                consumed_bits = 0;
                uncompressed_pixels = 0;
              
                for pixel = 1:length(image_vector)


                    if((pixel == 1))
                        left_n = NaN;
                    else
                        left_n = image_vector(pixel-1);
                    end


                    current = image_vector(pixel);


                    diff = (abs(left_n - current));
                    if(thres == 0)
                        header_bits = 1;

                    else 
                        header_bits = ceil(log2(thres+1)) + 1;

                    end                  
                    if(diff <= thres)  %any(diff == deltas)
                        cnt = cnt + 1;
                        consumed_bits = consumed_bits + header_bits;                     
                    else
                        uncompressed_pixels = uncompressed_pixels + 1;
                        consumed_bits = consumed_bits + header_bits + orginal_bits;
                    end
                    
                end
                    coverage_ratio = cnt/length(image_vector);
                   compressed_bits = coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( header_bits + orginal_bits);
                    
                %   cuurent_space_saving = 1 - compressed_bits/orginal_bits;
                   cuurent_space_saving = 1 - (consumed_bits/(length(image_vector) *(orginal_bits + log2(Q)))) ;
                    %fprintf('%.2f\n',100 * cuurent_space_saving);
                    ss_index = ss_index + 1;
                    space_savings(ss_index) = cuurent_space_saving;
                  %  fprintf('%f\n',100 * cuurent_space_saving);
%                     if(group_index == 3 && thres == 0 && dm == length(processed_maps(group_index).DMs_name) )
%                         fprintf('cnt = %i\n',cnt);
%                         fprintf('consumed_bits = %i\n',consumed_bits);
%                         fprintf('total number of pixels_v0 = %i\n',uncompressed_pixels + cnt);
%                         fprintf('total number of pixels_v1 = %i\n',length(image_vector));
%                          fprintf('consumed_bits according to cov ratio = %i\n',uncompressed_pixels * 9 + cnt);
% 
%                     end

        end
            
        fprintf('%.2f\n',100 * mean(space_savings));
        average_space_savings(thres+1) = round(100 * mean(space_savings),2);
    %end
    %fprintf('Average space savings for thres %i = %.2f\n',thres,100 * mean(space_savings));
    %fprintf('%.2f\n',100 * mean(space_savings));
        
end

%end