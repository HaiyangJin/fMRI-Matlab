function glasser16fslabel(hemi, roi)
% glasser16fslabel(hemi, roi)
%
% save labels from the *.mgz file. Note, this function needs to set up
% FreeSurfer appropriately.
%
% Input:
%    hemi      <str> 'lh' or 'rh'.
%    roi       <cell str> the roi names （see below）. Default is all ROIs. 
%
% Output:
%    a group of label files.
%
% Created by Haiyang Jin (2022-April-11)

if nargin < 1
    fprintf('Usage: glasser16fslabel(hemi, roi);\n');
    return;
end

assert(ismember(hemi, {'lh', 'rh'}));

thisdir = fileparts(mfilename('fullpath'));

colorlut = readtable(fullfile(thisdir, 'Glasser2016_ColorLUT.txt'), 'VariableNamingRule', 'preserve');
rois = colorlut.LabelName';

if ~exist('roi', 'var') || isempty(roi)
    roi = rois(2:end);
elseif ischar(roi)
    roi = {roi};
end

%%
% read the mgz file
vol = squeeze(load_mgh(fullfile(fm_2cmdpath(thisdir), [hemi '.glasser16_atlas.v1_0.mgz'])));
	
roiidx = ismember(roi, rois);

for i = find(roiidx)

    labelFn = sprintf('%s.%s_glasser16', hemi, roi{i});

    fs_mklabel(vol==i, 'fsaverage', labelFn);
end

end
