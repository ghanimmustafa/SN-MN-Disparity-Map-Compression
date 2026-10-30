this_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(fileparts(this_dir)));
addpath(genpath(fullfile(repo_root, 'matlab')));

if exist('DATASET_ROOT', 'var') && ~isempty(DATASET_ROOT)
    path_to_read = DATASET_ROOT;
else
    path_to_read = fullfile(repo_root, 'data');
end
disp_dirs = dir(fullfile(path_to_read, '*_disp'));
disp_dirs = disp_dirs([disp_dirs.isdir]);

for img_index = 1:length(disp_dirs)
    ground_truth_path = fullfile(path_to_read, disp_dirs(img_index).name);
    ground_truth = pfmread(fullfile(ground_truth_path, 'disp1.pfm'));
fraction_bits = 4;
max_integer_bits = ceil(log2(max(max(ground_truth))));
ground_truth_2 = fi(ground_truth,0,max_integer_bits+fraction_bits,fraction_bits);
ground_truth_2 = ground_truth_2.data;

fraction_bits = 1;
quantized_map = fi(ground_truth_2,0,max_integer_bits+fraction_bits,fraction_bits);
quantized_map = quantized_map.data;

%quantized_map  = round(ground_truth);
value = PSNR(quantized_map,ground_truth_2);
fprintf('%.2f\n',value);
%fprintf(strcat('PSNR with full integer rounding for ',image_names(img_index), ' = %.2f dB\n'),value);


end