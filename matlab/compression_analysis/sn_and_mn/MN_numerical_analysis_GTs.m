
% resolution_array = zeros(10,2);

reduction_factor = 1;
deltas = [0,1,3];
USE_JPEG_LS_MPO = false;
for Q = [1,2,4,8,16,32,64]

    for thres = 0
    ss_index = 0;
    space_savings =   zeros(length(GTs),1); 

    for dm = 1:length(GTs) 

            % MSB level qunatization: 
            processed_map = GTs{dm};
            processed_map = floor(processed_map/Q);
            [HEIGHT,WIDTH] = size(processed_map);
           % orginal_bits = (length(de2bi(max(max(processed_map)),'left-msb')));
            orginal_bits =  ceil(log2(max(max((processed_map))))) + fraction_bits  ;
            orginal_bits = double(orginal_bits); 
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
                elseif(column == WIDTH && (row > 1))
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
                    diff_tr = (abs(top_right_n - current));
                end

                if(thres == 0)
                    header_bits = 2;

                elseif( thres == 1)
                    header_bits = 4;

                else
                     header_bits = 5;

                end
                exp1 = (diff_l <= thres) || (diff_t <= thres) || (diff_tr <= thres);
                %exp2 = any(diff_l == deltas) || any(diff_t == deltas) || any(diff_tr == deltas);
                if(exp1) %%  
                    consumed_bits = consumed_bits + header_bits;
                    cnt = cnt + 1 ;
                else

                    consumed_bits = consumed_bits + header_bits + orginal_bits;

                end
                end

            end
               cuurent_space_saving = 1 - (consumed_bits/(WIDTH * HEIGHT * (orginal_bits + log2(Q))));
             %  coverage_ratio = cnt/(WIDTH * HEIGHT);
               %cuurent_space_saving = (orginal_bits - (coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( header_bits + orginal_bits)))/orginal_bits;
                ss_index = ss_index + 1;
                space_savings(ss_index) =  cuurent_space_saving;

    end
            
        %fprintf('Average space savings for thres %i = %.2f\n',thres,100 * mean(space_savings));
         
    end
    fprintf('%.2f\n',100 * mean(space_savings));
     
end
        
