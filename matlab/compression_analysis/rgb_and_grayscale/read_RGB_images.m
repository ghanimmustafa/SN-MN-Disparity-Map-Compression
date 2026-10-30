this_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(fileparts(this_dir)));
if exist('RGB_DATASET_DIR', 'var') && ~isempty(RGB_DATASET_DIR)
    rgb_dir = RGB_DATASET_DIR;
else
    rgb_dir = fullfile(repo_root, 'data', 'Art');
end

imagefiles = [dir(fullfile(rgb_dir, '*.ppm')); dir(fullfile(rgb_dir, '*.png'))];

RGB_images = {};
for k = 1:length(imagefiles)
    bbp = zeros(3,3);
    compression_ratio = zeros(3,3);
    orginal_bits = 8;
    test_image = imread(fullfile(rgb_dir, imagefiles(k).name));
    if size(test_image, 3) == 3
        RGB_images = [RGB_images, test_image];
    end
end