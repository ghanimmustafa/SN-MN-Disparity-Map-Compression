function MN_bitstream = MN_encoder(image)
image = double(image);
DISPARITY_BITS = 8;
HEADER_BITS = 2;
[HEIGHT,WIDTH] = size(image);
MN_bitstream = zeros(HEIGHT * WIDTH,HEADER_BITS + DISPARITY_BITS);
%% 00 --> Uncompressed, 01 --> Compressed ( left-neighbor ), 10 --> Compressed ( top-neighbor ), 11 --> Compressed ( top-right neighbor )

encoded_index = 1;
cnt = 0;
flag = 0;
for row =1:HEIGHT
    
                    
    if(((row > 1) && (image(row,1) == image(row-1,WIDTH))))

         MN_bitstream(encoded_index,:) = [bitget(image(row-1,WIDTH),DISPARITY_BITS:-1:1) 0 1];

         cnt = cnt + 1;
         encoded_index = encoded_index + 1;
         flag = 1;

    end
    
    
    for col =1:WIDTH
        if(~flag)
            if( ((col > 1) && ( image(row,col) == image(row,col-1))))


               MN_bitstream(encoded_index,:) = [bitget(image(row,col-1),DISPARITY_BITS:-1:1) 0 1];





            elseif((row >1) && ( image(row,col) == image(row-1,col)))

                MN_bitstream(encoded_index,:) = [bitget(image(row-1,col),DISPARITY_BITS:-1:1) 1 0];    



            elseif((row >1) && ( col < WIDTH) &&  ( image(row,col) == image(row-1,col+1)))

                MN_bitstream(encoded_index,:) = [bitget(image(row-1,col+1),DISPARITY_BITS:-1:1) 1 1];    

            else

                MN_bitstream(encoded_index,:) = [bitget(image(row,col),DISPARITY_BITS:-1:1) 0 0];  


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
    if(~isequal(MN_bitstream(i,DISPARITY_BITS + 1:end),[ 0 0]))
        
        compressed_cnt = compressed_cnt + 1;

        
    end
    
    
    
end

uncompressed_cnt = HEIGHT * WIDTH - compressed_cnt;
coverage_ratio = compressed_cnt/(compressed_cnt + uncompressed_cnt);

consumed_average_bit_length = (1 - coverage_ratio) * ( DISPARITY_BITS + HEADER_BITS) + coverage_ratio * HEADER_BITS;

CR = 100 * (DISPARITY_BITS - consumed_average_bit_length)/(DISPARITY_BITS);

fprintf('Compression Ratio is found to be = %.2f, average codeword = %.2f bits out of %i bits\n',CR,consumed_average_bit_length,DISPARITY_BITS);

end