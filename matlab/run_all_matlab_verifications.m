%% RUN_ALL_MATLAB_VERIFICATIONS
% Master reproducible verification & benchmarking script for:
%   M. Ghanim, O. Tasdizen, H. F. Ugurdag, and I. Hamzaoglu,
%   "An efficient algorithm for disparity map compression based on spatial
%    correlations and its low-cost hardware architecture,"
%   Integration, the VLSI Journal, vol. 93, p. 102069, 2023.
%
% Usage in MATLAB:
%   run('matlab/run_all_matlab_verifications.m')

clc;
clear;

this_dir  = fileparts(mfilename('fullpath'));
repo_root = fileparts(this_dir);
data_dir  = fullfile(repo_root, 'data');
addpath(genpath(this_dir));

fprintf('======================================================================\n');
fprintf('  SN / MN / HLB-MN / QLB-MN MATLAB Verification & Benchmark Suite\n');
fprintf('======================================================================\n\n');

%% ------------------------------------------------------------------------
%  PART 1: Preprocessing Transforms (RT, CRT, CT) & 3x3 Median Filtering
% -------------------------------------------------------------------------
fprintf('[Part 1] Verifying Preprocessing Transforms on stereo pairs in data/ ...\n');
stereo_dirs = dir(data_dir);
stereo_dirs = stereo_dirs([stereo_dirs.isdir] & ~ismember({stereo_dirs.name}, {'.', '..'}));

if ~isempty(stereo_dirs)
    scene_dir = fullfile(data_dir, stereo_dirs(1).name);
    png_files = dir(fullfile(scene_dir, '*.png'));
    if length(png_files) >= 2
        left_full  = imread(fullfile(scene_dir, png_files(1).name));
        right_full = imread(fullfile(scene_dir, png_files(2).name));
        left_patch  = left_full(1:min(64,end), 1:min(64,end), :);
        right_patch = right_full(1:min(64,end), 1:min(64,end), :);

        rt_left  = rankTransform(left_patch, 7);
        crt_left = CRT_v1(left_patch, 7, true);
        ct_left  = census(left_patch, 7);

        fprintf('  - Scene folder                                 : %s\n', stereo_dirs(1).name);
        fprintf('  - 7x7 Rank Transform (RT) output size          : %dx%d (range [%g, %g])\n', ...
            size(rt_left,1), size(rt_left,2), min(rt_left(:)), max(rt_left(:)));
        fprintf('  - 7x7 Complete Rank Transform (CRT) output size: %dx%dx%d (range [%g, %g])\n', ...
            size(crt_left,1), size(crt_left,2), size(crt_left,3), min(crt_left(:)), max(crt_left(:)));
        fprintf('  - 7x7 Census Transform (CT) output size        : %dx%d\n\n', ...
            size(ct_left,1), size(ct_left,2));
    end
else
    fprintf('  [SKIP] No stereo image folders found in data/.\n\n');
end

%% ------------------------------------------------------------------------
%  PART 2: Lossless SN, MN, HLB-MN, QLB-MN Compression & Decoding
% -------------------------------------------------------------------------
fprintf('[Part 2] Evaluating Lossless Compression & Bit-Accurate Decoding on data/*.mat ...\n');

mat_files = dir(fullfile(data_dir, '*.mat'));

fprintf('  %-36s | %-6s | %-8s | %-8s | %-8s | %-8s | %-10s\n', ...
    'Disparity Map File', 'Mode', 'SN (%)', 'MN (%)', 'HLB (%)', 'QLB (%)', 'Decode Check');
fprintf('  %s\n', repmat('-', 1, 100));

for idx = 1:length(mat_files)
    label = mat_files(idx).name;
    fpath = fullfile(data_dir, label);
    S = load(fpath);
    fn = fieldnames(S);
    raw_dm = double(S.(fn{1}));
    mf_dm  = double(my_median_filter(raw_dm, true));

    modes = {'Unfilt', raw_dm; '3x3 MF', mf_dm};
    for m = 1:size(modes, 1)
        mode_name = modes{m, 1};
        img       = modes{m, 2};
        [H, W]    = size(img);
        N         = H * W;

        % 1. Single-Neighbor (SN): 1-bit header when == left neighbor, else 9 bits
        vec = reshape(img', N, 1);
        sn_matches  = sum(vec(2:end) == vec(1:end-1));
        sn_cov      = sn_matches / N;
        sn_avg_bits = sn_cov * 1 + (1 - sn_cov) * 9;
        sn_sr       = 100 * (8 - sn_avg_bits) / 8;

        % Verify HLB-MN lossless encoding & decoding on a 64x64 crop
        crop = uint8(img(1:min(64,H), 1:min(64,W)));
        [cH, cW] = size(crop);
        evalc('hlb_stream = HLB_MN_encoder(crop);');
        dec_crop = zeros(cH, cW, 'uint8');
        p_idx = 0;
        for r = 1:cH
            for c = 1:cW
                p_idx = p_idx + 1;
                hdr = hlb_stream(p_idx, 9:10);
                if isequal(hdr, [0 0])
                    dec_crop(r, c) = uint8(hl_bi2de_msb(hlb_stream(p_idx, 1:8)));
                elseif isequal(hdr, [0 1])
                    if c == 1
                        dec_crop(r, c) = dec_crop(r-1, cW);
                    else
                        dec_crop(r, c) = dec_crop(r, c-1);
                    end
                elseif isequal(hdr, [1 0])
                    if mod(c, 2) == 1
                        dec_crop(r, c) = dec_crop(r-1, c);
                    else
                        dec_crop(r, c) = dec_crop(r-1, c-1);
                    end
                else
                    if mod(c, 2) == 1
                        dec_crop(r, c) = dec_crop(r-1, c+2);
                    else
                        dec_crop(r, c) = dec_crop(r-1, c+1);
                    end
                end
            end
        end
        assert(isequal(crop, dec_crop), 'HLB-MN decode mismatch!');

        % 2. Multi-Neighbor (MN - Full Line Buffer)
        left_mat = [ [NaN; img(1:end-1, end)], img(:, 1:end-1) ];
        top_mat  = [ NaN(1, W); img(1:end-1, :) ];
        tr_mat   = [ NaN(1, W); [img(1:end-1, 2:end), NaN(H-1, 1)] ];
        mn_match = (img == left_mat) | (img == top_mat) | (img == tr_mat);
        mn_cov   = sum(mn_match(:)) / N;
        mn_sr    = 100 * (8 - (mn_cov * 2 + (1 - mn_cov) * 10)) / 8;

        % 3. Half-Line Buffer MN (HLB-MN)
        hlb_t2 = NaN(H, W);
        hlb_t3 = NaN(H, W);
        hlb_t2(2:end, 1:2:end) = img(1:end-1, 1:2:end);
        hlb_t3(2:end, 1:2:W-2) = img(1:end-1, 3:2:W);
        hlb_t2(2:end, 2:2:end) = img(1:end-1, 1:2:end-1);
        hlb_t3(2:end, 2:2:W-1) = img(1:end-1, 3:2:W);
        hlb_match = (img == left_mat) | (img == hlb_t2) | (img == hlb_t3);
        hlb_cov   = sum(hlb_match(:)) / N;
        hlb_sr    = 100 * (8 - (hlb_cov * 2 + (1 - hlb_cov) * 10)) / 8;

        % 4. Quarter-Line Buffer MN (QLB-MN)
        qlb_t2 = NaN(H, W);
        qlb_t3 = NaN(H, W);
        for c = 1:W
            rem4 = mod(c - 1, 4);
            c_left_stored  = c - rem4;
            c_right_stored = c_left_stored + 4;
            if c_left_stored >= 1 && c_left_stored <= W
                qlb_t2(2:end, c) = img(1:end-1, c_left_stored);
            end
            if c_right_stored >= 1 && c_right_stored <= W
                qlb_t3(2:end, c) = img(1:end-1, c_right_stored);
            end
        end
        qlb_match = (img == left_mat) | (img == qlb_t2) | (img == qlb_t3);
        qlb_cov   = sum(qlb_match(:)) / N;
        qlb_sr    = 100 * (8 - (qlb_cov * 2 + (1 - qlb_cov) * 10)) / 8;

        fprintf('  %-36s | %-6s | %7.2f%% | %7.2f%% | %7.2f%% | %7.2f%% | PASS (0 err)\n', ...
            label, mode_name, sn_sr, mn_sr, hlb_sr, qlb_sr);
    end
end
fprintf('\n');

%% ------------------------------------------------------------------------
%  PART 3: Hardware Hex Vector I/O Verification
% -------------------------------------------------------------------------
fprintf('[Part 3] Verifying Hardware Hex Vector Conversion Utilities ...\n');
tmp_hex_file = fullfile(tempdir, 'test_hw_vector.txt');
test_patch   = uint8(raw_dm(1:16, 1:32));
Image_to_Hex_Vector(test_patch, tmp_hex_file);
restored_vec = Hex_Vector_to_Image(tmp_hex_file);
restored_img = uint8(reshape(restored_vec, 32, 16)');
if isfile(tmp_hex_file)
    delete(tmp_hex_file);
end
assert(isequal(test_patch, restored_img), 'Hex vector round-trip mismatch!');
fprintf('  - Image_to_Hex_Vector / Hex_Vector_to_Image round-trip: PASS (0 mismatches)\n\n');

fprintf('======================================================================\n');
fprintf('  ALL MATLAB VERIFICATIONS COMPLETED SUCCESSFULLY (0 ERRORS)\n');
fprintf('======================================================================\n');

function val = hl_bi2de_msb(bits)
    weights = 2 .^ (length(bits)-1 : -1 : 0);
    val = sum(double(bits(:)') .* weights);
end
