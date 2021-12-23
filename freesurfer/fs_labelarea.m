function labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, struDir)
% labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, struDir)
%
% This function calculates the area (mm^2) for the label file. [It should
% be the area on the ?h.white surface (I guess)].
%
% Inputs:
%    labelFn         <str> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     and struDir will be ignored. 
%    subjCode        <str> subject code in struDir. Default is empty.
%    vtxIdx          <int array> vertex indices (in this label) whose
%                     area will be calculated.
%    struDir         <str> $SUBJECTS_DIR.
%
% Output:
%    labelarea       <num> the label area in mm^2.
%
% Created by Haiyang Jin (22-Apr-2020)
%
% See also:
% fs_vtxarea

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
    warning('''fsaverage'' is used as ''subjCode'' by default.');
end
if ~exist('struDir', 'var') || isempty(struDir)
    struDir = '';
end

% load the label matrix
labelMat = fs_readlabel(labelFn, subjCode, struDir);

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
labelarea = fs_vtxarea(vtxIdx, subjCode, hemi, struDir);

end