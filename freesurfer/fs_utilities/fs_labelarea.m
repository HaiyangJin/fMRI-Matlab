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
%    vtxIdx          <integer array> vertex indices (in this label) whose
%                     area will be calculated.
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    labelarea       <numeric> the label area in mm^2.
%
% Created by Haiyang Jin (22-Apr-2020)
%
% See also:
% fs_vtxarea

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
    warning('''fsaverage'' is used as ''subjCode'' by default.');
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = '';
end

% load the label matrix
labelMat = fs_readlabel(labelFn, subjCode, struPath);

if isempty(labelMat)
    labelarea = 0;
    return;
end

% the vertex indices
if ~exist('vtxIdx', 'var') || isempty(vtxIdx)
    vtxIdx = labelMat(:, 1);
end

% calculate the all vertices by default
hemi = fm_2hemi(labelFn);

% calculate the area
labelarea = fs_vtxarea(vtxIdx, subjCode, hemi, struPath);

end