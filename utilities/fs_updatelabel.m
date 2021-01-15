function updateMat = fs_updatelabel(label1Fn, label2Fn, subjCode, ...
    updatefunc, saveBackup, which2update)
% updateMat = fs_updatelabel(label1Fn, label2Fn, subjCode, ...
%    updatefunc, saveBackup, which2update)
%
% This function update the 'which2update' label with the update funciton.
%
% When @setdiff (default) is used, the overlapping between the two labels
% will be identified and removed from the 'which2update' label.
%
% When @intersect is used, the non-overlapping between the two labels will be
% identified and removed them from the 'which2update' label.
% @union and @setxor have not been set properly.
%
% Inputs:
%    label1Fn      <string> the file name of one label.
%    label2Fn      <string> the file name of another label.
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    updatefunc    <function handle> the function used to udpate the label.
%                   Choices are:
%                     - @setdiff (default): set difference of two arrays;
%                     - @intersect: set intersection of two arrays;
%                     x @union: set union of two arrays;
%                     x @setxor: set exclusive OR of two arrays.
%    saveBackup    <logical> 1 [default]: save a copy of the to-be-trimmed
%                   label file; 0: do not save the backup. If 'saveBackup' is
%                   char, no backup file will be saved. Instead, the updated
%                   label will be saved as 'saveBackup'.
%    which2update  <integer> To update the first or the second label.
%                   Default is to trim label1Fn [i.e., 1].
%
% Output:
%    updateMat     <numeric array> Px5 matrix of the update label file.
%    save an updated label file.
%
% Created by Haiyang Jin (14-May-2020)

if ~exist('updatefunc', 'var') || isempty(updatefunc)
    updatefunc = @setdiff;
end

if ~exist('which2update', 'var') || isempty(which2update)
    which2update = 1; % trim label1Fn (use label2Fn as the reference label)
end
if ~exist('saveBackup', 'var') || isempty(saveBackup)
    saveBackup = 1;
end
assert(ismember(which2update, [1 2]), '''trimLabel'' has to be 1 or 2.');

% put the two labels together
theLabelFn = {label1Fn, label2Fn};
% the first label is the to-be-updated label (in theLabels)
theLabels = theLabelFn([which2update, setdiff([1 2], which2update)]);

% read label files and obtain their vertices
labelMatCell = cellfun(@(x) fs_readlabel(x, subjCode), theLabels, 'uni', false);
vtxCell = cellfun(@(x) x(:, 1), labelMatCell, 'uni', false);

% find the updated vertices (after removing the overlapping)
updateVtx = updatefunc(vtxCell{:});

% save the updated label matrix
origMat = labelMatCell{1};
updateMat = origMat(ismember(origMat(:, 1), updateVtx), :);

% backup the to-be-updated label
if ischar(saveBackup)
    udpateFn = saveBackup;
else
    fs_mklabel(origMat, subjCode, [theLabelFn{which2update} '.backup']);
    udpateFn = theLabelFn{which2update};
end

% save the updated label
fs_mklabel(updateMat, subjCode, udpateFn);

% check number of clusters
inforTable = fs_labelinfo(theLabelFn{which2update}, subjCode);
if max(inforTable.ClusterNo) > 1
    warning('There are %d clusters in the updated label file.', ...
        max(inforTable.ClusterNo));
end

end
