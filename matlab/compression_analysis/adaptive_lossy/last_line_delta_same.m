%% Semi-Optimal saving ratios by selecting same delta of the previous line (SDoPL) for HW implementation

function semi_optimal_SRs = last_line_delta_same(line_SRs,optimal_line_SRs,blocks_n)
    % This is for adaptive_SN/MN scripts only. 
    if(blocks_n == -1)
        lines = size(optimal_line_SRs,1);

        semi_optimal_SRs = zeros(lines,2);

        semi_optimal_SRs(1,:) = optimal_line_SRs(1,:);

        for L = 2:lines
            [~,previous_opt_delta] = max(line_SRs(L-1,:));
            semi_optimal_SRs(L,2) = previous_opt_delta;
            semi_optimal_SRs(L,1) = line_SRs(L,previous_opt_delta);
        end
        
    else
      
        
        lines = size(optimal_line_SRs,1);

        semi_optimal_SRs = zeros(lines,blocks_n,2);

        semi_optimal_SRs(1,:,:) = optimal_line_SRs(1,:,:);

        for L = 2:lines
            %[~,previous_opt_delta] = max(line_SRs(L-1,:,:));
            previous_opt_delta = optimal_line_SRs(L-1,:,2);
            
            semi_optimal_SRs(L,:,2) = previous_opt_delta;
            for block = 1:blocks_n
                semi_optimal_SRs(L,block,1) = (line_SRs(L,block,previous_opt_delta(block)));
                
            end
            
            
        end
                
        
        
        
        
    end


end