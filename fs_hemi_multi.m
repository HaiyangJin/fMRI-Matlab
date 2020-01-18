function [hemi, nHemi] = fs_hemi_multi(labelsFn)
% This function determine the hemispheres based on the filenames
%
% Created by Haiyang Jin (1/12/2019)

if ischar(labelsFn)
    labelsFn = {labelsFn};
end

hemis = unique(cellfun(@fs_hemi, labelsFn, 'UniformOutput', false));
nHemi = numel(hemis);

if nHemi ~= 1
    warning('These labels are for both hemispheres.');
    hemi = hemis;
else
    hemi = hemis{1};
end

