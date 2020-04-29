function labelTable = fs_labelinfo(labelList, subjList, struPath)
% labelTable = fs_labelinfo(labelList, subjList, struPath)
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
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    labelInfo       <struct> includes information about the label file.
%      .SubjCode       <cell> the input subjCode save as a cell.
%      .LabelName      <cell> the input labelFn (without path) but save as
%                       a cell.
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
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% all the possible combinations
[tempList, tempSubj] = ndgrid(labelList, subjList);

% read the label information
labelInfoCell = cellfun(@(x, y) labelinfo(x, y, struPath), tempList(:), tempSubj(:), 'uni', false);

labelTable = vertcat(labelInfoCell{:});

end

%% Obtain the label information separately
function labelInfo = labelinfo(labelFn, subjCode, struPath)

% read the label file
[labelMat, nVtx] = fs_readlabel(labelFn, subjCode, struPath);

if isempty(labelMat)
    labelInfo = [];
    return;
end

% maximum response
[maxResp, maxIdx] = max(labelMat(:, 5));

% coordiantes in RAS, MNI305(fsaverage) and Talairach space
RAS = labelMat(maxIdx, 2:4);
MNI305 = fs_ras2fsavg(RAS, subjCode);
Talairach = mni2tal(MNI305);

% label area (in mm^2)
labelSize = fs_labelarea(labelFn, subjCode, struPath);

%% Create a struct to save all the information
% inputs
SubjCode = {subjCode};
[~, fn, ext] = fileparts(labelFn);
LabelName = {[fn ext]};

% outinformation
Max = maxResp;
VtxMax = labelMat(maxIdx, 1);
Size = labelSize;
NVtxs = nVtx;

% save the out information as table
labelInfo = table(SubjCode, LabelName, Max, VtxMax, Size, MNI305, Talairach, NVtxs);

end