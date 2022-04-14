function wang15fslabel(hemi, roi)
% wang15fslabel(hemi, roi)
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
    fprintf('Usage: wang15fslabel(hemi, roi);\n');
    return;
end

assert(ismember(hemi, {'lh', 'rh'}));

rois = {'V1v', 'V1d', 'V2v', 'V2d', 'V3v', 'V3d', 'hV4', 'VO1', 'VO2', ... 
    'PHC1', 'PHC2', 'MST', 'hMT', 'LO2', 'LO1', 'V3b', 'V3a', 'IPS0', ...
    'IPS1', 'IPS2', 'IPS3', 'IPS4', 'IPS5', 'SPL1', 'FEF'};	   

if ~exist('roi', 'var') || isempty(roi)
    roi = rois;
elseif ischar(roi)
    roi = {roi};
end


%%
% read the mgz file
thisDir = fileparts(which('wang15fslabel'));
vol = squeeze(load_mgh(fullfile(fm_2cmdpath(thisDir), [hemi '.wang15_mplbl.mgz'])));
	
roiidx = ismember(roi, rois);

for i = find(roiidx)

    labelFn = sprintf('%s.%s_wang15', hemi, roi{i});

    fs_mklabel(vol==i, 'fsaverage', labelFn);
end

end





