function [uniTable, ds_subj, uniInfo] = fs_fun_uni_cosmo_ds(project, ...
    labelFn, sessCode, outputPath, runInfo, smooth, runSeparate)
% [uni_table, ds_subj, uni_info] = fs_fun_uni_cosmo_ds(project, ...
%     label_fn, sessCode, output_path, run_info, smooth, runSeparate)
% This function generates the data table for univariate analyses and the
% dataset used for CoSMoMVPA for FreeSurfer surface data.
%
% Inputs:
%    project            Project structure (obtained from fs_fun_projectinfo)
%    labelFn           the label filename (or 'lh' or 'rh', then the
%                       output will be the data for the whole hemisphere)
%    sessCode          session code in functional folder (bold subject code)
%    outputPath        where the outputs from fs_fun_labelsize are saved
%    runInfo           the run name (usually is 'loc' or 'main')
%    runSeparate        gather data for each run separately or not
% Outputs:
%    uniTable          the data table for univarate analyses
%    ds_subj            data set for CoSMoMVPA
%    uniInfo           information for this analyses
%
% Created by Haiyang Jin (12/12/2019)

% Input arguments
if nargin < 4
    outputPath = '';
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
else
    smooth = sprintf('_sm%d', smooth);
end

if (nargin < 7 || isempty(runSeparate)) && ~exist('runSeparate', 'var')
    runSeparate = 1;
end

% more information from inputs
runFn = sprintf('run_%s.txt', runInfo);  % run filename
parFn = sprintf('%s.par', runInfo); % paradigm filename
analysisExt = sprintf('%s%s', runInfo, smooth); % first parts of the analysis name

funcPath = project.funcPath;  % where the functional data are saved
boldPath = fullfile(funcPath, sessCode, 'bold'); % the bold folder

hemiOnly = any(ismember(labelFn, project.hemis));
if hemiOnly
    labelsize = 0;
    talCoor = zeros(1, 3);
 
else
    % warning if the label is not available for that subjCode and finish this
    % function
    subjCode = fs_subjcode(sessCode, funcPath);  % subjCode in $SUBJECTS_DIR
    if ~fs_checklabel(labelFn, subjCode)
        warning('Cannot find label "%s" for %s', labelFn, subjCode);
        uniInfo = table;
        ds_subj = table;
        uniTable = table;
        return;
    end
    
    % converting the label file to logical matrix
    dtMatrix = fs_readlabel(subjCode, labelFn);
    vtxROI = dtMatrix(:, 1);
    
    % calculate the size of this label file and save the output
    [labelsize, talCoor] = fs_fun_labelsize(project, sessCode, labelFn, outputPath);
    
end

hemi = fs_hemi(labelFn);  % which hemisphere

% read the run file
[runNames, nRun] = fs_fun_readrun(runFn, project, sessCode);
if ~runSeparate; nRun = 1; end % useful later for deciding the analysis name

% Pre-define the cell array for saving ds
dsCell = cell(1, nRun);

for iRun = 1:nRun

    % set iRunStr as '' when there is only "1" run
    iRunStr = erase(num2str(iRun), num2str(nRun^2));
    analysisName = sprintf('%s%s%s.%s', ...
        analysisExt, project.boldext, iRunStr, hemi); % the analysis name
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

%% Convert the ds_subj to ds for univariate analysis
uniInfo = table;
uniInfo.Label = {labelFn};
uniInfo.nVertices = nVertex;
uniInfo.LabelSize = labelsize;
uniInfo.TalCoordinate = talCoor;
uniInfo.SubjCode = {sessCode};

nRowUni = size(ds_subj.samples, 1);
uniTable = [repmat(uniInfo, nRowUni, 1), fs_cosmo_univariate(ds_subj)];  

end