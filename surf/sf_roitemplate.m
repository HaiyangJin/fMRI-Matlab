function [tempname, refcoord] = sf_roitemplate(labelfn)
% [tempname, refcoord] = sf_roitemplate(labelfn)
%
% Obtain the template label file name.
%
% Input:
%    labelfn     <str> the label file name.
%
% Output:
%     tempname   <str> the corresponding template label file.
%     refcoord   <vec> the corresponding reference coordinate.
%
% Created by Haiyang Jin (2022-Nov-24)

if nargin < 1
    fprintf('Usage: template = sf_roitemplate(labelfn);\n');
    return;
end

%% load possible ROI names and their reference
% ref = readtable('ROI_ref.csv');
% refTable = table;
% refTable.rois = ref.ROIs;
% refTable.lh=[ref.lh_X, ref.lh_Y, ref.lh_Z];
% refTable.rh=[ref.rh_X, ref.rh_Y, ref.rh_Z];
% save('ROI_ref.mat', "refTable");

load(fullfile(which('sf_roitemplate'), '..', '..', 'reflabels', ...
    'custom', 'ROI_ref.mat'), 'refTable');

% ROIs
rois = lower(refTable.rois); 
isroi = cellfun(@(x) contains(labelfn, x), rois);
if sum(isroi)==0
    tempname = 'na';
    refcoord = 0;
    return;
end

assert(sum(isroi)>=1, 'Cannot idenitfy an unique ROI name.')
theroi = rois{isroi};

% hemi
hemi = fm_2hemi(labelfn);
isleft = strcmp(hemi, 'lh');

% the template label name
tempname = sprintf('%s.roi.%s.label', hemi, theroi);

% the reference coordinates
refcoord = refTable{isroi, 3-isleft};

end