function [uni_table, ds_subj, uni_info] = fs_fun_uni_cosmo_ds(projStr, ...
    label_fn, subjCode_bold, output_path, run_info, smooth, runSeparate)
% [uni_table, ds_subj, uni_info] = fs_fun_uni_cosmo_ds(projStr, ...
%     label_fn, subjCode_bold, output_path, run_info, smooth, runSeparate)
% This function generates the data table for univariate analyses and the
% dataset used for CoSMoMVPA for FreeSurfer surface data.
%
% Inputs:
%    projStr            Project structure (e.g., fw_projectinfo)
%    label_fn           the label filename (or 'lh' or 'rh', then the
%                       output will be the data for the whole hemisphere)
%    subjCode_bold      subject code in fMRI folder
%    output_path        where the outputs from fs_fun_labelsize are saved
%    run_info           the run name (usually is 'loc' or 'main')
%    runSeparate        gather data for each run separately or not
% Outputs:
%    uni_table          the data table for univarate analyses
%    ds_subj            data set for CoSMoMVPA
%    uni_info           information for this analyses
%
% Created by Haiyang Jin (12/12/2019)

% Input arguments
if nargin < 4
    output_path = '';
end

if nargin < 5 || isempty(run_info)
    run_info = 'loc';
    warning('Analyses for localizer scans were conducted by default.');
end
if strcmpi(run_info, 'loc'); runSeparate = 0; end

if nargin < 6 || isempty(smooth)
    if strcmpi(run_info, 'main')
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
run_fn = sprintf('run_%s.txt', run_info);  % run filename
par_fn = sprintf('%s.par', run_info); % paradigm filename
analysis_ext = sprintf('%s%s', run_info, smooth); % first parts of the analysis name

fMRI_path = projStr.fMRI;  % where the functional data are saved
boldPath = fullfile(fMRI_path, subjCode_bold, 'bold'); % the bold folder

hemiOnly = any(ismember(label_fn, projStr.hemis));
if hemiOnly
    labelsize = 0;
    talCoor = zeros(1, 3);
 
else
    % warning if the label is not available for that subjCode and finish this
    % function
    subjCode = fs_subjcode(subjCode_bold, fMRI_path);  % subjCode in $SUBJECTS_DIR
    if ~fs_checklabel(label_fn, subjCode)
        warning('Cannot find label "%s" for %s', label_fn, subjCode);
        uni_info = table;
        ds_subj = table;
        uni_table = table;
        return;
    end
    
    % converting the label file to logical matrix
    dtMatrix = fs_readlabel(label_fn, subjCode);
    vtxROI = dtMatrix(:, 1);
    
    % calculate the size of this label file and save the output
    [labelsize, talCoor] = fs_fun_labelsize(projStr, subjCode_bold, label_fn, output_path);
    
end

hemi = fs_hemi(label_fn);  % which hemisphere

% read the run file
[runNames, nRun] = fs_fun_readrun(run_fn, projStr, subjCode_bold);
if ~runSeparate; nRun = 1; end % useful later for deciding the analysis name

% Pre-define the cell array for saving ds
ds_cell = cell(1, nRun);

for iRun = 1:nRun

    % set iRunStr as '' when there is only "1" run
    iRunStr = erase(num2str(iRun), num2str(nRun^2));
    analysisName = sprintf('%s%s%s.%s', ...
        analysis_ext, projStr.boldext, iRunStr, hemi); % the analysis name
    % the beta file
    beta_file = fullfile(boldPath, analysisName, 'beta.nii.gz');
    
    % read the paradigm file
    par_file = fullfile(boldPath, runNames{iRun}, par_fn);
    parInfo = fs_readpar(par_file);

     % load the nifti from FreeSurfer and get the cosmo dataset for this run
     ds_run = fs_cosmo_surface(beta_file, ...
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
     ds_cell(1, iRun) = {this_ds};
    
end

% stack multiple ds.sample
ds_subj = cosmo_stack(ds_cell,1);

%% Convert the ds_subj to ds for univariate analysis
uni_info = table;
uni_info.Label = {label_fn};
uni_info.nVertices = nVertex;
uni_info.LabelSize = labelsize;
uni_info.TalCoordinate = talCoor;
uni_info.SubjCode = {subjCode_bold};

nRowUni = size(ds_subj.samples, 1);
uni_table = [repmat(uni_info, nRowUni, 1), fs_cosmo_univariate(ds_subj)];  

end