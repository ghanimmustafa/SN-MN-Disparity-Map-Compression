function average_compressed_consecutivity = find_mean_consecutivity_SN(compressed_locations,comp_index)
    differenced_vector = circshift(compressed_locations,-1);
    differenced_vector = differenced_vector - compressed_locations;
    compressed_hist = zeros(comp_index,1);
    cnt = 0;
    for i = 1:comp_index

       if(differenced_vector(i) == 1)
           cnt = cnt + 1;

       else
           compressed_hist(i) = cnt;
           cnt = 0;
       end

    end
    average_compressed_consecutivity = mean(compressed_hist+1);

end

