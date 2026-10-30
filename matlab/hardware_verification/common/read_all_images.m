% READ_ALL_IMAGES Dynamically load disparity maps for compression analysis.
%   By default, reads from the repository's `data/` directory (or a custom
%   `DATASET_ROOT` directory if defined in the workspace).
%   Automatically discovers any `*_disp` stereo subdirectories or `*.mat`
%   disparity map files in the target folder without hardcoded image names.

this_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(fileparts(fileparts(this_dir)));
addpath(genpath(fullfile(repo_root, 'matlab')));

if exist('DATASET_ROOT', 'var') && ~isempty(DATASET_ROOT)
    path_to_read = DATASET_ROOT;
else
    path_to_read = fullfile(repo_root, 'data');
end

transform_names = ["Rank","CRT_v1","Census"];
Rank_DMs = [];
CRT_DMs = [];
Census_DMs = [];
Rank_extensions = ["-perfectrank_DisparityMap_7x5","-perfectrank_DisparityMap_7x7","-perfectrank_DisparityMap_MF_7x5","-perfectrank_DisparityMap_MF_7x7"];
CRT_extensions  = ["-perfectCRT_DisparityMap_7x5","-perfectCRT_DisparityMap_7x7","-perfectCRT_DisparityMap_MF_7x5","-perfectCRT_DisparityMap_MF_7x7"];
Census_extensions = ["-perfectCensus_DisparityMap_7x1","-perfectCensus_DisparityMap_MF_7x1"];

if ~exist('median_filter', 'var')
    median_filter = false;
end
if median_filter
    Rank_extensions = Rank_extensions(contains(Rank_extensions,"MF"));
    CRT_extensions = CRT_extensions(contains(CRT_extensions,"MF"));
    Census_extensions = Census_extensions(contains(Census_extensions,"MF"));
else
    Rank_extensions = Rank_extensions(~contains(Rank_extensions,"MF"));
    CRT_extensions = CRT_extensions(~contains(CRT_extensions,"MF"));
    Census_extensions = Census_extensions(~contains(Census_extensions,"MF"));
end

disp_dirs = dir(fullfile(path_to_read, '*_disp'));
disp_dirs = disp_dirs([disp_dirs.isdir]);

if ~isempty(disp_dirs)
    image_names = strings(1, length(disp_dirs));
    for img_index = 1:length(disp_dirs)
        folder_name = disp_dirs(img_index).name;
        img_name = erase(folder_name, '_disp');
        image_names(img_index) = img_name;
        img_path = fullfile(path_to_read, folder_name);
        for tr_index = 1:length(transform_names)
            if tr_index == 1
                for i = 1:length(Rank_extensions)
                    Rank_DMs = [Rank_DMs, load(fullfile(img_path, transform_names(tr_index), strcat(img_name, Rank_extensions(i), '.mat')))];
                end
            elseif tr_index == 2
                for i = 1:length(CRT_extensions)
                    CRT_DMs = [CRT_DMs, load(fullfile(img_path, transform_names(tr_index), strcat(img_name, CRT_extensions(i), '.mat')))];
                end
            else
                for i = 1:length(Census_extensions)
                    Census_DMs = [Census_DMs, load(fullfile(img_path, transform_names(tr_index), strcat(img_name, Census_extensions(i), '.mat')))];
                end
            end
        end
    end
else
    % Dynamically load all .mat disparity maps in path_to_read
    mat_files = dir(fullfile(path_to_read, '*.mat'));
    image_names = strings(1, length(mat_files));
    GTs = {};
    for s_idx = 1:length(mat_files)
        [~, stem, ~] = fileparts(mat_files(s_idx).name);
        image_names(s_idx) = string(stem);
        raw_struct = load(fullfile(path_to_read, mat_files(s_idx).name));
        fn = fieldnames(raw_struct);
        dm = double(raw_struct.(fn{1}));
        entry.disparity_map = dm;
        entry.md = my_median_filter(dm, true);
        Rank_DMs = [Rank_DMs, entry];
        GTs = [GTs, {dm}];
    end
end
