function [labelTable, fscmd] = fs_surfcluster(sessCode, anaName,...
    labelFn, sigFn, thmin, outPath, funcPath, struPath)
% [labelTable, fscmd] = fs_surfcluster(sessCode, anaName,...
%     labelFn, [sigFn='sig.nii.gz', thmin=1.3, outPath=pwd, funcPath, struPath])
%
% This function obtains the size of the label (ROI) from FreeSurfer
% commands (mri_surfcluster). All the output information will be calculated
% based on white surface.
%
% Inputs:
%    sessCode         <string> session code in funcPath.
%    anaName          <string> name of the analysis folder.
%    lableFn          <string> label filename.
%                  OR <string> the contrast name within the analysis
%                      folder.
%    sigFn            <string> based on which data file to obtain the
%                      cluster. Default is sig.nii.gz.
%    thmin            <string> the minimal threshold. Default is 1.3.
%    outPath          <string> where the temporary output file is saved.
%    funcPath         <string> the full path to the functional folder.
%    struPath         <string> $SUBJECTS_DIR.
%
% Outputs:
%    labelTable       <table> includes information about the label file.
%      .SubjCode       <cell> the input subjCode save as a cell.
%      .AnalysisName   <cell> the analysis name save as a cell.
%      .LabelName      <cell> the input labelFn (without path) but save as 
%                       a cell.
%      .ClusterNo      <integer> the number (index) of the cluster.
%      .Max            <numeric> the peak response value.
%      .VtxMax         <integer> vertex index of the peak response.
%      .Size           <numeric> the size (area) of the label in mm^2.
%      .MNI305         <1x3 numeric vector> coordinates (XYZ) of VtxMax in
%                       MNI305 (fsaverage) space.
%      .NVtxs          <integer> number of vertices in this label.
%
% Created by Haiyang Jin (18-Nov-2019)

if ~exist('sigFn', 'var') || isempty(sigFn)
    sigFn = 'sig.nii.gz';
end
if ~exist('thmin', 'var') || isempty(thmin)
    thmin = 1.3;  % 0.05
end
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = pwd;
end
outPath = fullfile(outPath, 'SurfCluster');
if ~exist(outPath, 'dir'); mkdir(outPath); end
if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

isLabel = endsWith(labelFn, '.label');
hemi = fs_2hemi(anaName);
subjCode = fs_subjcode(sessCode, funcPath);

% create cmd for label if needed
if isLabel
    assert(strcmp(fs_2hemi(labelFn), hemi), ['Hemisphere information in '...
        'the analysis name (%s) does not match that in the label name (%s).'],...
        anaName, labelFn);
    conName = fs_2contrast(labelFn);
    
    % make sure the label exists
    if isempty(fs_readlabel(labelFn, subjCode, struPath))
        labelTable = [];
        fscmd = '';
        return;
    end
    fscmd_label = sprintf(' --clabel %s', fullfile(struPath, subjCode, ...
        'label', labelFn));
else
    conName = labelFn;
    fscmd_label = '';
end

% sig file
sigfile = fullfile(funcPath, sessCode, 'bold', anaName, conName, sigFn);

% create the freesurfer command
outFn = sprintf('cluster=%s=%s=%s.txt', anaName, labelFn, subjCode);
outFile = fullfile(outPath, outFn);

% create and run FreeSurfer commands
fscmd = sprintf(['mri_surfcluster --in %s --subject %s ' ...
    '--surf white --thmin %d --hemi %s --sum %s --nofixmni%s'], ...
    sigfile, subjCode, thmin, hemi, outFile, fscmd_label);
isnotok = system(fscmd);
assert(~isnotok, 'FreeSurfer commands (mri_surfcluster) failed.');

%% load the output file from mri_surfcluster
tempcell = importdata(outFile, ' ', 36);

tempdata = tempcell.data;
ClusterNo = tempdata(:, 1);
Max = tempdata(:, 2);
VtxMax = tempdata(:, 3);
Size = tempdata(:, 4);
MNI305 = tempdata(:, 5:7);
NVtxs = tempdata(:, 8);

% save inputs
nCluster = numel(ClusterNo);
SubjCode = repmat({subjCode}, nCluster, 1);
AnalysisName = repmat({anaName}, nCluster, 1);
[~, fn, ext] = fileparts(labelFn);
LabelName = repmat({[fn ext]}, nCluster, 1);

% save the out information as table
labelTable = table(SubjCode, AnalysisName, LabelName, ClusterNo, Max, VtxMax, Size, MNI305, NVtxs);

end