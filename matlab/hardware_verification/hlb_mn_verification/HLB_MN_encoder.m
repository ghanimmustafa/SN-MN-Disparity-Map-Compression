function HLB_MN_bitstream = HLB_MN_encoder(image)
DISPARITY_BITS = 8;
HEADER_BITS = 2;
[HEIGHT,WIDTH] = size(image);
HLB_MN_bitstream = zeros(HEIGHT * WIDTH,HEADER_BITS + DISPARITY_BITS);
%% 00 --> Uncompressed, 01 --> Compressed ( left-neighbor ), 10 --> Compressed ( top-neighbor ), 11 --> Compressed ( top-right neighbor )
%% If the current pixel index is odd ( starting with 1), compare it with top and top-right-right pixels
%% If the current pixel index is even ( starting with 1), compare it with top-left and top-right pixels
encoded_index = 1;
cnt = 0;
flag = 0;
for row =1:HEIGHT
   % if(row > 1)
   %     HLB = image(row-1,1:2:end);
   % end
   
    
                    
    if(((row > 1) && (image(row,1) == image(row-1,WIDTH))))

         HLB_MN_bitstream(encoded_index,:) = [bitget(image(row-1,WIDTH),DISPARITY_BITS:-1:1) 0 1];

         cnt = cnt + 1;
         encoded_index = encoded_index + 1;
         flag = 1;

    end
    
    k = 0;
    for col =1:WIDTH
        if(mod(col,2) == 0)
            IS_EVEN = 1;
        else
            IS_EVEN = 0;
        end
        if(~flag)
            if( ((col > 1) && ( image(row,col) == image(row,col-1))))


               HLB_MN_bitstream(encoded_index,:) = [bitget(image(row,col-1),DISPARITY_BITS:-1:1) 0 1];



            %% Top neighbor (odd-index) comparsions:    

            elseif((row >1) && (~IS_EVEN) && (image(row,col) == image(row-1,col)))

                HLB_MN_bitstream(encoded_index,:) = [bitget(image(row-1,col),DISPARITY_BITS:-1:1) 1 0];    
            %% Top left neighbor (even-index) comparsions:    

            elseif((row >1) && (IS_EVEN) && (col > 1) &&  (image(row,col) == image(row-1,col-1)))

                HLB_MN_bitstream(encoded_index,:) = [bitget(image(row-1,col-1),DISPARITY_BITS:-1:1) 1 0];  

            %% Top-right-right (odd-index) comparsions:    
            elseif((row >1) && ( col <= (WIDTH-2)) &&  (~IS_EVEN) && ( image(row,col) == image(row-1,col+2)))

                HLB_MN_bitstream(encoded_index,:) = [bitget(image(row-1,col+2),DISPARITY_BITS:-1:1) 1 1]; 
            %% Top-right  (even-index) comparsions:       
            elseif((row >1) && ( col <= (WIDTH-1)) &&  (IS_EVEN) && ( image(row,col) == image(row-1,col+1)))

                HLB_MN_bitstream(encoded_index,:) = [bitget(image(row-1,col+1),DISPARITY_BITS:-1:1) 1 1];
            else

                HLB_MN_bitstream(encoded_index,:) = [bitget(image(row,col),DISPARITY_BITS:-1:1) 0 0];  


            end
            encoded_index = encoded_index + 1;
            
        else
            flag = 0;
            
        end
        
    end
end

fprintf('Encoding is done .. now calculating compression ratio .. \n');
fprintf('%i many times start/end encoding case happened\n',cnt);
compressed_cnt = 0;
for i = 1:(HEIGHT * WIDTH)
    if(~isequal(HLB_MN_bitstream(i,DISPARITY_BITS + 1:end),[ 0 0]))
        
        compressed_cnt = compressed_cnt + 1;

        
    end
    
    
    
end

uncompressed_cnt = HEIGHT * WIDTH - compressed_cnt;
coverage_ratio = compressed_cnt/(compressed_cnt + uncompressed_cnt);

consumed_average_bit_length = (1 - coverage_ratio) * ( DISPARITY_BITS + HEADER_BITS) + coverage_ratio * HEADER_BITS;

CR = 100 * (DISPARITY_BITS - consumed_average_bit_length)/(DISPARITY_BITS);

fprintf('Compression Ratio is found to be = %.2f, average codeword = %.2f bits out of %i bits\n',CR,consumed_average_bit_length,DISPARITY_BITS);

end