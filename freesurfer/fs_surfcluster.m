function [roisize, talCoor, VtxMax, nVtx] = fs_surfcluster(sessCode, anaName,...
    labelFn, sigFn, thmin, outPath, funcPath, struPath)
% [roisize, talCoor, VtxMax, nVtx] = fs_surfcluster(sessCode, anaName,...
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
%    roisize          <string> size in mm2.
%    talCoor          <string> the talairach coordinates for the peak
%                       (maybe).
%    VtxMax           <string> the vertex number of the peak response.
%    nVtx             <string> number of vertices in this label.
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
    fscmd_label = sprintf(' --clabel %s', fullfile(struPath, subjCode, ...
        'label', labelFn));
else
    conName = labelFn;
    fscmd_label = '';
end
    
% sig file
sigfile = fullfile(funcPath, sessCode, 'bold', anaName, conName, sigFn);

% create the freesurfer command
outFn = sprintf('cluster=%s=%s=%s.txt', anaName, conName, subjCode);
outFile = fullfile(outPath, outFn);

% create and run FreeSurfer commands
fscmd = sprintf(['mri_surfcluster --in %s --subject %s ' ...
    '--surf white --thmin %d --hemi %s --sum %s%s'], ...
    sigfile, subjCode, thmin, hemi, outFile, fscmd_label);
isnotok = system(fscmd);
assert(~isnotok, 'FreeSurfer commands (mri_surfcluster) failed.');

%% load the output file from mri_surfcluster
tempcell = importdata(outFile, ' ', 36);

tempdata = tempcell.data;

VtxMax = tempdata(3);
roisize = tempdata(4);
talCoor = tempdata(5:7);
nVtx = tempdata(8);

end