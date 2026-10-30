cd rgb8bit\
imagefiles = dir('*.ppm');
for k = 1:4
    test_image = imread(imagefiles(k).name);
    downsampled_img = imresize(test_image, [500, 500]);
    imwrite(downsampled_img,strcat(erase(imagefiles(k).name,'.ppm'),'.jpg'))
end
fprintf('Avg. resolution for RGB images = %i x %i \n',round(mean(WIDTHS)),round(mean(HEIGHTS)));
cd ..
cd gray8bit\
imagefiles = dir('*.pgm');
for k = 1:4
    test_image = imread(imagefiles(k).name);
    downsampled_img = imresize(test_image, [500, 500]);
    imwrite(downsampled_img,strcat(erase(imagefiles(k).name,'.pgm'),'.jpg'))    
end
