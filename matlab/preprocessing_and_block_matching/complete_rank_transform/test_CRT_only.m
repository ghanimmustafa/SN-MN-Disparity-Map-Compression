this_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(fileparts(this_dir)));
addpath(genpath(fullfile(repo_root, 'matlab')));

if exist('DATASET_ROOT', 'var') && ~isempty(DATASET_ROOT)
    dataset_path = DATASET_ROOT;
else
    dataset_path = fullfile(repo_root, 'data');
end

scene_dirs = dir(dataset_path);
scene_dirs = scene_dirs([scene_dirs.isdir] & ~ismember({scene_dirs.name}, {'.', '..'}));
target_folder = fullfile(dataset_path, scene_dirs(1).name);
png_files = dir(fullfile(target_folder, '*.png'));
left = imread(fullfile(target_folder, png_files(1).name));
CRT_left = CRT_v1(left, 3, true);
left_grayscale = rgb2gray(left);