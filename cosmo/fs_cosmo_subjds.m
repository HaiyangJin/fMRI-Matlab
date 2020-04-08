function [ds_subj, condInfo] = fs_cosmo_subjds(sessCode, labelFn, template, ...
    funcPath, runInfo, smooth, runSeparate)
% [ds_subj, condInfo] = fs_cosmo_subjds(sessCode, labelFn, template, ...
%    funcPath, runInfo, smooth, runSeparate)
%
% This function load the FreeSurfer surface data as the dataset used for
% CoSMoMVPA.
%
% Inputs:
%     sessCode         <string> session code in functional folder (bold
%                       subject code).
%     labelFn          <string> the label filename (or 'lh' or 'rh', then
%                       the output will be the data for the whole
%                       hemisphere).
%     template         <string> 'fsaverage' or 'self'. fsaverage is the default.
%     funcPath         <string> the full path to the functional folder.
%     runInfo          <string> the run name (usually is 'loc' or 'main').
%     smooth           <string> or <numeric> the smooth used.
%     runSeparate      <logical> gather data for each run separately or
%                       not.
%
% Outputs:
%     ds_subj          <structure> data set for CoSMoMVPA.
%     condInfo         <structure> condition information for this analysis.
%
% Created by Haiyang Jin (12-Dec-2019)

% Input arguments
if nargin < 3 || isempty(template)
    template = '';
elseif ~endsWith(template, '_')
    template = [template, '_'];
end
    
if nargin < 4 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

if nargin < 5 || isempty(runInfo)
    runInfo = 'loc';
    warning('Analyses for localizer scans were conducted by default.');
end
if strcmpi(runInfo, 'loc'); runSeparate = 0; end

if nargin < 6 || isempty(smooth)
    if strcmpi(runInfo, 'main')
        smooth = '_sm0';
    else
        smooth = '';
    end
elseif isnumeric(smooth)
    smooth = sprintf('_sm%d', smooth);
elseif ischar(smooth)
    if ~strcmp(smooth(1), '_')
        smooth = ['_' smooth];
    end
end

if (nargin < 7 || isempty(runSeparate)) && ~exist('runSeparate', 'var')
    runSeparate = 1;
end

% more information from inputs
runFn = sprintf('run_%s.txt', runInfo);  % run filename
parFn = sprintf('%s.par', runInfo); % paradigm filename
analysisExt = sprintf('%s%s', runInfo, smooth); % first parts of the analysis name

boldPath = fullfile(funcPath, sessCode, 'bold'); % the bold folder

hemiOnly = any(ismember(labelFn, {'lh', 'rh'}));

% warning if the label is not available for that subjCode and finish this
% function
subjCode = fs_subjcode(sessCode, funcPath);  % subjCode in $SUBJECTS_DIR
if ~fs_checklabel(labelFn, subjCode) && ~hemiOnly
    warning('Cannot find label "%s" for %s', labelFn, subjCode);
    condInfo = table;
    ds_subj = table;
    return;
end

% converting the label file to logical matrix
if ~hemiOnly
    dtMatrix = fs_readlabel(subjCode, labelFn);
    vtxROI = dtMatrix(:, 1);
end

hemi = fs_hemi(labelFn);  % which hemisphere

% read the run file
[runNames, nRun] = fs_readrun(runFn, sessCode, funcPath);
if ~runSeparate; nRun = 1; end % useful later for deciding the analysis name

%% Load data from runs
% Pre-define the cell array for saving ds
dsCell = cell(1, nRun);

for iRun = 1:nRun
    
    % set iRunStr as '' when there is only "1" run
    iRunStr = erase(num2str(iRun), num2str(nRun^2));
    analysisName = sprintf('%s%s%s.%s', ...
        template, analysisExt, iRunStr, hemi); % the analysis name
    % the beta file
    betaFile = fullfile(boldPath, analysisName, 'beta.nii.gz');
    
    % read the paradigm file
    parFile = fullfile(boldPath, runNames{iRun}, parFn);
    parInfo = fs_readpar(parFile);
    
    % load the nifti from FreeSurfer and get the cosmo dataset for this run
    ds_run = fs_cosmo_surface(betaFile, ...
        'targets', parInfo.Condition,...
        'labels', parInfo.Label,...
        'chunks', iRun); % cosmo_fmri_fs_dataset(thisBoldFilename); % with the whole brain
    
    % apply the roi mask to the whole dataset
    if ~hemiOnly
        roiMask = zeros(1, size(ds_run.samples, 2));
        roiMask(vtxROI) = 1;
    else
        roiMask = ones(1, size(ds_run.samples, 2));
    end
    this_ds = cosmo_slice(ds_run, logical(roiMask), 2);
    nVertex = size(this_ds.samples, 2);
    
    % save the dt in a cell for further stacking
    dsCell(1, iRun) = {this_ds};
    
end

% stack multiple ds.sample
ds_subj = cosmo_stack(dsCell,1);

%% save the condition information
condInfo = table;
condInfo.Label = {labelFn};
condInfo.nVertices = nVertex;
condInfo.SubjCode = {sessCode};

end