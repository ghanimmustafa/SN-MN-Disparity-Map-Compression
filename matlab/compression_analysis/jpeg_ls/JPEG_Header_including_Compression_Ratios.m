CR_w_o = [
36.18
46.43
25.76
34.61
43.88
57.15
48.23
57.47
52.20
62.33
36.97
46.19
50.18
58.31
30.65
40.72
38.41
48.71
32.89
42.01
   

];

CR_with_H = zeros(length(Rank_DMs),1);
image_cont_bits = zeros(length(Rank_DMs),1);
for i =1:length(Rank_DMs)
    
 image = Rank_DMs(i).md;
 image_cont_bits = JPEG_CONTAINER(image);
 
 orginal_total_bits = 8 * size(image,1) * size(image,2);
 %CR_with_H(i) = (CR_w_o(i) * orginal_total_bits + image_cont_bits)/orginal_total_bits;
    
    
    
    
    
    
    
    
    
    
    
    
    
end

fprintf('Average JPEG CONTAINER memory words = %.2f\n',mean(image_cont_bits)/128);