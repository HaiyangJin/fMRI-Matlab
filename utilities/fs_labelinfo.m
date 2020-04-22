function labelInfo = fs_labelinfo(labelFn, subjCode, struPath)
% labelInfo = fs_labelinfo(labelFn, subjCode, struPath)
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
%      .SubjCode       <string> the input subjCode.
%      .Labelname      <string> the input labelFn (without path).
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

if ~exist('labelFn', 'var') || isempty(labelFn)
    labelFn = 'lh.cortex.label';
    warning('''%s'' is loaded by default.', labelFn);
end
if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
    warning('''%s'' is used as ''subjCode'' by default.', subjCode);
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% read the label file
[labelMat, nVtx] = fs_readlabel(labelFn, subjCode, struPath);

% find the peak vertice
[maxValue, vtxMax] = max(labelMat(:, 5));

% coordiantes in RAS, MNI305(fsaverage) and Talairach space
RAS = labelMat(vtxMax, 2:4);
MNI305 = fs_ras2fsavg(RAS, subjCode);
Talairach = mni2tal(MNI305);

% label area (in mm^2)
labelSize = fs_labelarea(labelFn, subjCode, struPath);

%% Create a struct to save all the information
labelInfo = struct;

% inputs
labelInfo.SubjCode = subjCode;
[~, fn, ext] = fileparts(labelFn);
labelInfo.Labelname = [fn ext];

% outinformation
labelInfo.Max = maxValue;
labelInfo.VtxMax = vtxMax;
labelInfo.Size = labelSize;
labelInfo.MNI305 = MNI305;
labelInfo.Talairach = Talairach;
labelInfo.NVtxs = nVtx;

end