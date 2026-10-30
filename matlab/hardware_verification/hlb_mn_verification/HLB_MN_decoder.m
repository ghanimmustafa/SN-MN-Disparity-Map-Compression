%% For now let's decode bitstream only without memory words
if ~exist('encoded_file_name', 'var')
    encoded_file_name = 'hw_mf_hlb_mn_encoded.txt';
end
HLB_MN_bitstream = BinaryFileToBinaryArray(encoded_file_name);
test_img = filtered;
[total_pixels,n_bits] = size(HLB_MN_bitstream);
[HEIGHT,WIDTH] = size(test_img);
%encoded_img = permute(reshape(HLB_MN_bitstream, HEIGHT, WIDTH, n_bits), [1 2 3]);
decoded_img = zeros(HEIGHT,WIDTH);
same_neighbor_locs = [];
H_BITS = 9:10;
UNCOMP_H = [0 0];
LEFT_H = [0 1];
TOP_OR_TOP_LEFT_H = [1 0];
TOP_R_OR_TOP_RR_H = [1 1];
pixel_cnt = 0;
for row = 1:HEIGHT
        if(mod(row,100) == 0)
            fprintf('%i many rows are decoded, %i many rows left.. \n',row,HEIGHT-row)
        end
    for col = 1:WIDTH
        pixel_cnt = pixel_cnt + 1;
        curr_enc_disparity = HLB_MN_bitstream(pixel_cnt,:);%reshape(encoded_img(row,col,:),1,[]);

        if(mod(col,2) == 0)
            IS_EVEN = true;
        else
            IS_EVEN = false;
        end
        if(col == 1 && row == 1)
            left_n = NaN;
        elseif(col == 1 && row > 1)
            left_n = decoded_img(row-1,WIDTH);
        else
            left_n = decoded_img(row,col-1);
        end
        if(row == 1)
            top_n = NaN;
            top_r_n = NaN;
            top_r_r_n = NaN;
            top_l_n = NaN;
        else
            if(col > 1)
                top_l_n = decoded_img(row-1,col-1);
            else
                top_l_n = NaN;
            end
            if(col >= WIDTH)
               top_r_n = NaN; 
            else
               top_r_n = decoded_img(row-1,col+1);  
            end

            if(col >= (WIDTH-1))
               top_r_r_n = NaN; 
            else
               top_r_r_n = decoded_img(row-1,col+2);  
            end
            top_n = decoded_img(row-1,col);
        end
        if(isequal(curr_enc_disparity(H_BITS),UNCOMP_H))
            decoded_img(row,col) = bi2de(curr_enc_disparity(1:(n_bits - 2) ),'left-msb');

        elseif(isequal(curr_enc_disparity(H_BITS),LEFT_H))
            decoded_img(row,col) = left_n;
        end
        if(IS_EVEN)
            if(isequal(curr_enc_disparity(H_BITS),TOP_OR_TOP_LEFT_H))
                decoded_img(row,col) = top_l_n;
                       
            elseif (isequal(curr_enc_disparity(H_BITS),TOP_R_OR_TOP_RR_H))
                decoded_img(row,col) = top_r_n;
                 %fprintf('Top_right_n case : row = %i, col = %i\n',row,col);     
              
            end


        else
            if(isequal(curr_enc_disparity(H_BITS),TOP_OR_TOP_LEFT_H))
                decoded_img(row,col) = top_n;
                flag_cnt = 4;
               
            elseif (isequal(curr_enc_disparity(H_BITS),TOP_R_OR_TOP_RR_H))
                decoded_img(row,col) = top_r_r_n;
               
            end


        end

    end

end

if(isequal(decoded_img,test_img))
    fprintf('Decoded image and orginal image are equal. \n')
else
    fprintf('Decoded image and orginal image are NOT equal. \n')
end