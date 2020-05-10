function fs_mksublabel(labelFn, subjCode, vtxIdx, infixSubFn)
% fs_mksublabel(labelFn, subjCode, vtxIdx, infixSubFn)
%
% This function saves the vtxIdx in labelFn as a new label.
%
% Inputs:
%    labelFn       <string> the file name of the label file.
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    vtxIdx        <integer vector> Indices of vertices to be saved in the
%                   new label file.
%    infixSubFn    <string> strings to be added before '.label'. Default is
%                   '.sub'.
%
% Output:
%    a new label file (saved at $SUBJECTS_DIR/label/).
%
% Created by Haiyang Jin (10-May-2020)

if ~exist('infixSubFn', 'var') || isempty(infixSubFn)
    infixSubFn = '.sub';
elseif ~startsWith(infixSubFn, '.')
    infixSubFn = ['.' infixSubFn];
end

% read the label
labelMat = fs_readlabel(labelFn, subjCode);

% only keep the vertices matching vtxIdx
isSub = ismember(labelMat(:, 1), vtxIdx);
subLabelMat = labelMat(isSub, :);

% create the new label filename
newLabelFn = [erase(labelFn, '.label'), infixSubFn, '.label'];

% save the new label
fs_save2label(subLabelMat, subjCode, newLabelFn);

end