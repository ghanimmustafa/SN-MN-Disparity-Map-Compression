function out_img = non_padded_median_filters(in_img,n,m)
    assert(n==m); %% filter size
    assert(n > 1 && m > 1);
    assert (mod(n,2)~= 0);
    center_ind = (n+1)/2;
    columns_to_unfilter = n - center_ind;
    %fprintf('columns_to_unfilter = %i\n',columns_to_unfilter);
    out_img = medfilt2(in_img,[n m]);
    out_img = out_img(columns_to_unfilter+1:end-columns_to_unfilter,:);
    tmp_img = in_img(columns_to_unfilter+1:end-columns_to_unfilter,:);
    out_img(:,1:columns_to_unfilter) = tmp_img(:,1:columns_to_unfilter);
    unfiltered_end_rows = columns_to_unfilter-1;
    out_img(:,end-unfiltered_end_rows:end) =  tmp_img(:,end-unfiltered_end_rows:end);    







end