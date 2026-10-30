

reduction_factor = 1;
deltas = [0,1,3];
for Q = [1,2,4,8,16,32,64,128,256]

for thres = 0
    space_savings =  zeros(length(GTs),1);
     ss_index = 0;
    for dm = 1:length(GTs) %
       
       


        processed_map = GTs{dm};



                % MSB level qunatization: 
               processed_map = floor(processed_map/Q);

        image_vector = reshape(processed_map',1,numel(processed_map))';
        orginal_bits = ceil(log2(max(max(processed_map)))) + fraction_bits;
    %     fprintf('orginal_bits = %i\n',orginal_bits);
    
    

        consumed_bits = 0;
        cnt = 0;
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

            elseif( thres == 1)
                header_bits = 2;

            else
                 header_bits = 3;

            end                  
            if(any(diff == deltas))  %any(diff == deltas)
                
                cnt = cnt + 1;
                consumed_bits = consumed_bits + header_bits;
            else
                consumed_bits = consumed_bits + header_bits + orginal_bits;

            end





        end
           % coverage_ratio = cnt/length(image_vector);
           % compressed_bits = coverage_ratio * header_bits + ( 1 - coverage_ratio) * ( header_bits + orginal_bits);

          % cuurent_space_saving = 1 - compressed_bits/orginal_bits;
           cuurent_space_saving = 1 - (consumed_bits/(length(image_vector) *(orginal_bits+log2(Q)))) ;
            %fprintf('%.2f\n',100 * cuurent_space_saving);
            ss_index = ss_index + 1;
            space_savings(ss_index) = cuurent_space_saving;
         %   fprintf('%f\n',100 * cuurent_space_saving);

    end
    %fprintf('Average space savings for thres %i = %.2f\n',thres,100 * mean(space_savings));
end
fprintf('%.2f\n',100 * mean(space_savings));

end


    
        
