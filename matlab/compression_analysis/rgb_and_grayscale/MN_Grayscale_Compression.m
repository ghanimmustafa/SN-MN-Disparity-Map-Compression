cd gray8bit\
imagefiles = dir('*.pgm');
for k = 1:length(imagefiles)
    %fprintf(strcat('Processed Image Name: ',imagefiles(k).name,'\n'));
    test_image = imread(imagefiles(k).name);
    bbp = zeros(4);
    space_savings = zeros(4);
    orginal_bits = 8;
    [HEIGHT,WIDTH] = size(test_image);


        processed_map = double(test_image);

        for thres = 0
            consumed_bits = 0;
            for row=1:HEIGHT

                for col =1:WIDTH
                    if(col == 1 && row == 1)
                        left_n = NaN;
                    elseif(col == 1  && row >1)
                        left_n = processed_map(row-1,WIDTH);

                    else
                        left_n = processed_map(row,col-1);
                    end
                    if(row == 1)
                        top_n = NaN;
                        top_r_n = NaN;
                    else
                        if(col == WIDTH)
                            top_r_n = NaN;
                            top_n = processed_map(row-1,col);
                        else
                            top_r_n = processed_map(row-1,col+1);
                            top_n = processed_map(row-1,col);
                        end
                    end

                    
                    current = processed_map(row,col);
                     if( thres == 0)
                         header_bits = 2;
                         index = 1;
        
                      elseif ( thres == 1)
                         header_bits = 4;
                         index = 2;   
                     elseif (thres == 3)
                         header_bits = 5;
                         index = 3;    
                     
                     elseif (thres == 7)
                         header_bits = 6;
                         index = 4;    
                     end 

                    if((abs(left_n - current) <= thres) || (abs(top_n - current) <= thres) || (abs(top_r_n - current) <= thres))     

                        consumed_bits = consumed_bits + header_bits;

                    else
                        consumed_bits = consumed_bits + header_bits + orginal_bits;
                    end

                end

            end

            
             space_savings(index) = (1 - (consumed_bits/(HEIGHT*WIDTH*orginal_bits)));
             bbp(index) = orginal_bits*(1-space_savings(index));
             
        end
    

    fprintf('%.2f\n',mean(bbp(index)));

end