function output = rankTransform(img, rankSize)
% RANKTRANSFORM Compute the non-parametric Rank Transform of an image.
%   output = rankTransform(img, rankSize) computes the number of pixels
%   in each (rankSize x rankSize) neighborhood whose intensity is strictly
%   less than the center pixel intensity.

if size(img, 3) == 3
    img_gray = rgb2gray(img);
else
    img_gray = img;
end
[y, x] = size(img_gray);

borders = floor(rankSize / 2); % limit to exclude image borders when filtering
center  = borders + 1;
img_out = zeros(y - 2*borders, x - 2*borders);

for iy = 1 + borders : y - borders
    for ix = 1 + borders : x - borders
        f = img_gray(iy - borders : iy + borders, ix - borders : ix + borders);
        iix = ix - borders;
        iiy = iy - borders;
        img_out(iiy, iix) = sum(sum(f < f(center, center))); % Rank transform
    end
end

output = img_out;
end
