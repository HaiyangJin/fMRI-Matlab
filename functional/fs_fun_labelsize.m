function [roisize, talCoor, nVtx, VtxMax] = fs_fun_labelsize(projStr, subjCodeBold, ...
    labelFn, outputPath, betaFn, thmin)
% This function obtains the size of the label (ROI) from FreeSurfer
% commands (mri_surfcluster).
%
% Inputs:
%    projStr           matlab structure for the project (obtained from fs_fun_projectinfo)
%                      This is specific for each project.
%    subjCodeBold     subject code for functional data
%    lableFn          label filename
%    outputPath       where the temporary output file is saved
%    betaFn           based on which data file to obtain the cluster
%    thmin             the minimal threshold (magic number)
% Outputs:
%    roisize           size in mm2
%    talCoor           the talairach coordinates for the peak (maybe)
%    nVtx              number of vertices in this label
%    VtxMax            the vertex number of the peak response
%
% Created by Haiyang Jin (18/11/2019)

if nargin < 4 || isempty(outputPath)
    outputPath = '.';
end
outputPath = fullfile(outputPath, 'Label_Size');
if nargin < 5 || isempty(betaFn)
    betaFn = 'beta.nii.gz';
end
if ~exist(outputPath, 'dir'); mkdir(outputPath); end

if nargin < 6 || isempty(thmin)
    thmin = 0.001;
end

% load project information
boldext = projStr.boldext;

hemi = fs_hemi(labelFn);
subjCode = fs_subjcode(subjCodeBold, projStr.funcPath);

% label file
labelfile = fullfile(projStr.subjects, subjCode, 'label', labelFn);

% beta file
analysisfolder = sprintf('loc%s.%s', boldext, hemi);
betafile = fullfile(fullfile(projStr.funcPath, subjCodeBold, ...
        'bold', analysisfolder, betaFn));

% create the freesurfer command
outFn = sprintf('cluster%%%s%%%s.txt', labelFn, subjCode);
outFile = fullfile(outputPath, outFn);
fs_cmd = sprintf(['mri_surfcluster --in %s --clabel %s --subject %s ' ...
    '--surf inflated --thmin %d --hemi %s --sum %s'], ...
    betafile, labelfile, subjCode, ...
    thmin, hemi, outFile);

system(fs_cmd);

%% load the output file from mri_surfcluster
tempcell = importdata(outFile, ' ', 36);

tempdata = tempcell.data;

VtxMax = tempdata(3);
roisize = tempdata(4);
talCoor = tempdata(5:7);
nVtx = tempdata(8);

end