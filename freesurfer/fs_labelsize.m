function [roisize, talCoor, nVtx, VtxMax] = fs_labelsize(sessCode, template,...
    labelFn, funcPath, outputPath, betaFn, thmin)
% [roisize, talCoor, nVtx, VtxMax] = fs_labelsize(sessCode, template,...
%    labelFn, funcPath, outputPath, betaFn, thmin)
%
% This function obtains the size of the label (ROI) from FreeSurfer
% commands (mri_surfcluster).
%
% Inputs:
%     sessCode         <string> session code in funcPath.
%     template         <string> 'fsaverage' or 'self'. fsaverage is the default.
%     lableFn          <string> label filename
%     funcPath         <string> the full path to the functional folder. 
%     outputPath       <string> where the temporary output file is saved.
%     betaFn           <string> based on which data file to obtain the
%                       cluster.
%     thmin            <string> the minimal threshold (magic number).
%
% Outputs:
%     roisize          <string> size in mm2
%     talCoor          <string> the talairach coordinates for the peak
%                       (maybe).
%     nVtx             <string> number of vertices in this label.
%     VtxMax           <string> the vertex number of the peak response.
%
% Created by Haiyang Jin (18-Nov-2019)

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

hemi = fs_hemi(labelFn);
subjCode = fs_subjcode(sessCode, funcPath);

% label file
labelfile = fullfile(funcPath, subjCode, 'label', labelFn);

% beta file
analysisfolder = sprintf('loc%s.%s', template, hemi);
betafile = fullfile(fullfile(funcPath, sessCode, ...
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