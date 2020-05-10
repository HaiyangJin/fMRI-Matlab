function labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, struPath)
% labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, struPath)
%
% This function calculates the area (mm^2) for the label file. [It should
% be the area on the ?h.white surface (I guess)].
%
% Inputs:
%    labelFn         <string> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     and struPath will be ignored. 
%    subjCode        <string> subject code in struPath. Default is empty.
%    vtxIdx          <integer array> indices of vertices whose areas will
%                     be calculated. Default is all vertices in the label.
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    labelarea       <numeric> the label area in mm^2.
%
% Created by Haiyang Jin (22-Apr-2020)

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = '';
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = '';
end

% load the label matrix
labelMat = fs_readlabel(labelFn, subjCode, struPath);

% decide the hemisphere for the label file
hemi = fs_2hemi(labelFn);
curvFile = [hemi '.area'];

% add path to curvFile if path is included in labelFn
labelPath = fileparts(labelFn);
if ~isempty(labelPath)
    curvFile = fullfile(labelPath, '..', 'surf', curvFile);
end

% read the area for fsaverage if the label is on fsaverage surface
template = fs_2template(labelFn, '', 'self');
trgSubj = fs_trgsubj(subjCode, template);

% areas for all vertices
area = fs_readcurv(curvFile, trgSubj, struPath);

% calculate the all vertices by default
if ~exist('vtxIdx', 'var') || isempty(vtxIdx)
    vtxIdx = labelMat(:, 1);
end

% sum the areas of vertices in the label
labelarea = sum(area(vtxIdx));

end