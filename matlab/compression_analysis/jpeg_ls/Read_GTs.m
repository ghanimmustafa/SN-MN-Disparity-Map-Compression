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

GT_DMs = {};
for img_index = 1:length(disp_dirs)
    img_path = fullfile(path_to_read, disp_dirs(img_index).name);
    GT_DMs = [GT_DMs, pfmread(fullfile(img_path, 'disp1.pfm'))];
end