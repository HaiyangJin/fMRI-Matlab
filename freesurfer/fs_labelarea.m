function labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, surface)
% labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, surface)
%
% This function calculates the area (mm^2) for the label file. [It should
% be the area on the ?h.white surface (I guess)].
%
% Inputs:
%    labelFn         <str> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     will be ignored. 
%    subjCode        <str> subject code in $SUBJECTS_DIR. Default is 
%                     'fsaverage'.
%    vtxIdx          <int array> vertex indices (in this label) whose
%                     area will be calculated. [not the row number in this
%                     label file.]
%    surface         <str> surface without hemisphere information, which
%                     will be obtained from [labelFn].
%
% Output:
%    labelarea       <num> the label area in mm^2.
%
% Created by Haiyang Jin (22-Apr-2020)
%
% See also:
% fs_vtxarea

if nargin < 1
    fprintf('Usage: labelarea = fs_labelarea(labelFn, subjCode, vtxIdx, surface);\n');
    return;
end

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
    warning('''fsaverage'' is used as ''subjCode'' by default.');
end

% load the label matrix
labelMat = fs_readlabel(labelFn, subjCode);

if isempty(labelMat)
    labelarea = 0;
    return;
end

% the vertex indices (calculate the all vertices by default)
if ~exist('vtxIdx', 'var') || isempty(vtxIdx)
    vtxIdx = labelMat(:, 1);
end

if ~exist('surface', 'var') || isempty(surface)
    % by default fs_vexarea() will use ?h.area
    surface = fm_2hemi(labelFn); % hemisphere information only
end

if ischar(surface)
    if ~startsWith(surface, {'lh', 'rh'})
        surface = [fm_2hemi(labelFn) '.' surface];
    else
        assert(strcmp(fm_2hemi(labelFn), fm_2hemi(surface)), ['The hemisphere ' ...
            'information of labelFn (%s) and surface (%s) does not match.'], ...
            fm_2hemi(labelFn), fm_2hemi(surface));
    end
end

% calculate the area
labelarea = fs_vtxarea(vtxIdx, subjCode, surface);

end