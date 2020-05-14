function updateMat = fs_setdifflabel(label1Fn, label2Fn, subjCode, which2update, saveBackup)
% updateMat = fs_setdifflabel(label1Fn, label2Fn, subjCode, which2update, saveBackup)
%
% This function identifies the overlapping between the two labels (similar
% to the Matlab function 'setdiff') and remove them from the 'which2Trim.
%
% Inputs:
%    label1Fn      <string> the file name of one label.
%    label2Fn      <string> the file name of another label.
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    which2update  <integer> To update the first or the second label.
%                   Default is to trim label1Fn [i.e., 1].
%    saveBackup    <logical> 1 [default]: save a copy of the to-be-trimmed
%                   label file; 0: do not save the backup.
%
% Output:
%    updateMat     <numeric array> Px5 matrix of the update label file.
%    save an updated label file.
%
% Created by Haiyang Jin (14-May-2020)

if ~exist('which2update', 'var') || isempty(which2update)
    which2update = 1; % trim label1Fn (use label2Fn as the reference label)
end
if ~exist('saveBackup', 'var') || isempty(saveBackup)
    saveBackup = 1;
end
assert(ismember(which2update, [1 2]), '''trimLabel'' has to be 1 or 2.');

% put the two labels together
theLabelFn = {label1Fn, label2Fn};
theLabels = theLabelFn([which2update, setdiff([1 2], which2update)]);

% read label files and obtain their vertices
labelMatCell = cellfun(@(x) fs_readlabel(x, subjCode), theLabels, 'uni', false);
vtxCell = cellfun(@(x) x(:, 1), labelMatCell, 'uni', false);

% find the udpated vertices (after removing the overlapping)
updateVtx = setdiff(vtxCell{:});

% save the updated label matrix
origMat = labelMatCell{which2update};
updateMat = origMat(ismember(origMat(:, 1), updateVtx), :);

% backup the to-be-updated label
if saveBackup
    fs_save2label(origMat, subjCode, [theLabelFn{which2update} '.backup']);
end

% save the updated label
fs_save2label(updateMat, subjCode, theLabelFn{which2update});

end