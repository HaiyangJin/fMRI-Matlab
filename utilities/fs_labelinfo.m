function labelTable = fs_labelinfo(labelList, subjList, byCluster, fmin, struPath)
% labelTable = fs_labelinfo(labelList, subjList, byCluster=0, struPath)
%
% This function gathers the information about the label file.
%
% Inputs:
%    labelFn         <string> filename of the label file (with or without
%                     path). If path is included in labelFn, 'subjCode'
%                     and struPath will be ignored. Default is
%                     'lh.cortex.label'.
%    subjCode        <string> subject code in struPath. Default is
%                     fsaverage.
%    byCluster       <logical> whether output the information for clusters
%                     separately if there are multiple contiguous clusters
%                     for the label. Default is 0.
%    fmin            <numeric> The (absolute) minimum value for vertices to
%                     be used for summarizing information. Default is 0,
%                     i.e., all vertices will be used.
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    labelInfo       <struct> includes information about the label file.
%      .SubjCode       <cell> the input subjCode save as a cell.
%      .LabelName      <cell> the input labelFn (without path) but save as
%                       a cell.
%      .ClusterNo      <integer> the cluster number. If sepCluster is 0,
%                       .ClusterNo is the total number of contiguous
%                       clusters. If sepCluster is 1, .ClusterNo is the
%                       cluster number for each row (cluster).
%      .Max            <numeric> the peak response value.
%      .VtxMax         <integer> vertex index of the peak response.
%      .Size           <numeric> the size (area) of the label in mm^2.
%      .MNI305         <1x3 numeric vector> coordinates (XYZ) of VtxMax in
%                       MNI305 (fsaverage) space.
%      .Talairach      <1x3 numeric vector> coordinates (XYZ) of VtxMax in
%                       Talairach space (use the same method used in
%                       FreeSurfer converting from MNI305 to Talairach).
%      .NVtxs          <integer> number of vertices in this label.
%
% Created by Haiyang Jin (22-Apr-2020)

if ~exist('labelList', 'var') || isempty(labelList)
    labelList = {'lh.cortex.label'};
    warning('''%s'' is loaded by default.', labelList{1});
elseif ischar(labelList)
    labelList = {labelList};
end
if ~exist('subjList', 'var') || isempty(subjList)
    subjList = {'fsaverage'};
    warning('''%s'' is used as ''subjCode'' by default.', subjList{1});
elseif ischar(subjList)
    subjList = {subjList};
end
if ~exist('byCluster', 'var') || isempty(byCluster)
    byCluster = 0;
end
if ~exist('fmin', 'var') || isempty(fmin)
    fmin = 0;
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% all the possible combinations
[tempList, tempSubj] = ndgrid(labelList, subjList);

% read the label information
labelInfoCell = cellfun(@(x, y) labelinfo(x, y, byCluster, fmin, struPath),...
    tempList(:), tempSubj(:), 'uni', false);

labelTable = vertcat(labelInfoCell{:});

end

%% Obtain the label information separately
function labelInfo = labelinfo(labelFn, subjCode, byCluster, fmin, struPath)

% get the cluster (contiguous)
[clusterNo, nCluster] = fs_clusterlabel(labelFn, subjCode, fmin);

% read the label file
labelMat = fs_readlabel(labelFn, subjCode, struPath);

if isempty(labelMat)
    labelInfo = [];
    return;
end

if byCluster
    clusters = transpose(1:nCluster);
    matCell = arrayfun(@(x) labelMat(clusterNo == x, :), clusters, 'uni', false);
else
    clusters = nCluster;
    matCell = {labelMat};
end

% maximum response
[~, maxIdx] = cellfun(@(x) max(abs(x(:, 5))), matCell);
maxResp = arrayfun(@(x, y) x{1}(y, 5), matCell, maxIdx);

% coordiantes in RAS, MNI305(fsaverage) and Talairach space
RAS = arrayfun(@(x, y) x{1}(y, 2:4), matCell, maxIdx, 'uni', false);
MNI305 = cellfun(@(x) fs_self2fsavg(x, subjCode), RAS, 'uni', false);
Talairach = cellfun(@mni2tal, MNI305, 'uni', false);

% label area (in mm^2)
labelSize = cellfun(@(x) fs_labelarea(labelFn, subjCode, x(:, 1), struPath),...
    matCell, 'uni', false);

%% Create a struct to save all the information
% inputs
SubjCode = repmat({subjCode}, numel(clusters), 1);
[~, fn, ext] = fileparts(labelFn);
LabelName = repmat({[fn ext]}, numel(clusters), 1);

% outinformation
ClusterNo = clusters;
Max = maxResp;
VtxMax = arrayfun(@(x, y) x{1}(y, 1), matCell, maxIdx);
Size = labelSize;
NVtxs = cellfun(@(x) size(x, 1), matCell);

% save fmin
fmin = repmat(fmin, numel(clusters), 1);

% save the out information as table
labelInfo = table(SubjCode, LabelName, ClusterNo, Max, VtxMax, Size, MNI305, Talairach, NVtxs, fmin);

end