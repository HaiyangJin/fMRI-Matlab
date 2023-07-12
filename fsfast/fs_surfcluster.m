function [labelTable, fscmd] = fs_surfcluster(sessCode, anaName,...
    labelFn, surffn, sigFn, thmin, outPath)
% [labelTable, fscmd] = fs_surfcluster(sessCode, anaName,...
%     labelFn, [surffn = 'white', sigFn='sig.nii.gz', thmin=1.3, outPath=pwd])
%
% This function obtains the size of the label (ROI) from FreeSurfer
% commands (mri_surfcluster). All the output information will be calculated
% based on white surface.
%
% Inputs:
%    sessCode         <str> session code in $FUNCTIONALS_DIR.
%    anaName          <str> name of the analysis folder.
%    lableFn          <str> label filename.
%                  OR <str> the contrast name within the analysis
%                      folder.
%    surffn           <str> the surface to be used. Default is 'white'.
%    sigFn            <str> based on which data file to obtain the
%                      cluster. Default is sig.nii.gz.
%    thmin            <num> the minimal threshold. Default is 1.3.
%    outPath          <str> where the temporary output file is saved.
%
% Outputs:
%    labelTable       <table> includes information about the label file.
%      .SubjCode       <cell> the input subjCode save as a cell.
%      .Analysis       <cell> the analysis name save as a cell.
%      .Label          <cell> the input labelFn (without path) but save as 
%                       a cell.
%      .ClusterNo      <int> the number (index) of the cluster.
%      .Max            <num> the peak response value.
%      .VtxMax         <int> vertex index of the peak response.
%      .Size           <num> the size (area) of the label in mm^2.
%      .MNI305         <1x3 num vec> coordinates (XYZ) of VtxMax in
%                       MNI305 (fsaverage) space.
%      .NVtxs          <int> number of vertices in this label.
%
% Created by Haiyang Jin (18-Nov-2019)
%
% See also:
% fs_surflabel

if nargin < 1
    fprintf(['Usage: [labelTable, fscmd] = fs_surfcluster(sessCode, anaName,' ...
        ' labelFn, surffn, sigFn, thmin, outPath);\n']);
    return;
end

if ~exist('surffn', 'var') || isempty(surffn)
    surffn = 'white';
end

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
struDIR = getenv('SUBJECTS_DIR');

isLabel = endsWith(labelFn, '.label');
hemi = fm_2hemi(anaName);
template = fs_2template(anaName, '', 'self');
subjCode = fs_subjcode(sessCode);
trgSubj = fs_trgsubj(subjCode, template);

% create cmd for label if needed
if isLabel
    assert(strcmp(fm_2hemi(labelFn), hemi), ['Hemisphere information in '...
        'the analysis name (%s) does not match that in the label name (%s).'],...
        anaName, labelFn);
    conName = fm_2contrast(labelFn);
    
    % make sure the label exists
    if isempty(fs_readlabel(labelFn, subjCode, struDIR))
        labelTable = [];
        fscmd = '';
        return;
    end
    fscmd_label = sprintf(' --clabel %s', fullfile(struDIR, subjCode, ...
        'label', labelFn));
else
    conName = labelFn;
    fscmd_label = '';
end

% sig file
sigfile = fullfile(getenv('FUNCTIONALS_DIR'), sessCode, 'bold', anaName, conName, sigFn);

% create the freesurfer command
outFn = sprintf('cluster=%s=%s=%s=thmin%0.2f.txt', anaName, labelFn, ...
    subjCode, thmin);
outFile = fullfile(outPath, outFn);

% create and run FreeSurfer commands
fscmd = sprintf(['mri_surfcluster --in %s --subject %s ' ...
    '--surf %s --thmin %d --hemi %s --sum %s --nofixmni%s'], ...
    sigfile, trgSubj, surffn, thmin, hemi, outFile, fscmd_label);
isnotok = system(fscmd);
assert(~isnotok, 'FreeSurfer commands (mri_surfcluster) failed.');

%% load the output file from mri_surfcluster
tmpcell = importdata(outFile, ' ', 36);

tmpdata = tmpcell.data;
ClusterNo = tmpdata(:, 1);
Max = tmpdata(:, 2);
VtxMax = tmpdata(:, 3)+1; % the Matlab vertex index
Size = tmpdata(:, 4);
MNI305 = tmpdata(:, 5:7);
NVtxs = tmpdata(:, 8);

% save inputs
nCluster = numel(ClusterNo);
SubjCode = repmat({subjCode}, nCluster, 1);
Analysis = repmat({anaName}, nCluster, 1);
Surface = repmat({surffn}, nCluster, 1);
[~, fn, ext] = fileparts(labelFn);
Label = repmat({[fn ext]}, nCluster, 1);

% save the out information as table
labelTable = table(SubjCode, Analysis, Label, ClusterNo, Max, VtxMax, Size, MNI305, NVtxs, Surface);

end