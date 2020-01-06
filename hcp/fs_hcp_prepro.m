function fs_hcp_prepro(HCP_path, sessStr, template)
% This function creates directory structure for analyses in FreeSurfer for
% results obtained from Human Connectome Project pipeline.
%
% Inputs:
%    HCP_path       path to the HCP results ('Path/to/HCP/') [Default is the
%                   current working directory]
%    sessStr        strings (or prefix) for session information (e.g.,
%                   'faceword' is the prefix for 'faceword01', 'faceword02',
%                   'faceword03'. sessStr will help to identify all the
%                   session folders. In order to perform this
%                   transformation for only one session, just set the sessStr
%                   as the full name of the session name (e.g., 'faceword01').
%    template       template used for projecting functional data ('self' or
%                   'fsaverage')
% Output:
%    a subfolder called FreeSurfer is built in HCP/. It contains the
%    directory structure (but not the structure data) for analyses in
%    FreeSurfer.
% Dependency:
%    FreeSurfer   (Please make sure FreeSurfer is installed and sourced properly.)
%
% Created by Haiyang Jin (5/01/2020).

% get the environment variable 
fshome_path = getenv('FREESURFER_HOME');
if isempty(fshome_path)
    error('Please make sure FreeSurfer is installed and sourced properly.');
end

if nargin < 1 || isempty(HCP_path)
    HCP_path = pwd;
end

if nargin < 2 || isempty(sessStr) || strcmp(sessStr, '.')
    sessStr = fs_hcp_projname(HCP_path);
end
% add '*' if last letter is not '*'
if sessStr(end) ~= '*' && ~strcmp(sessStr, '.')
    sessStr = [sessStr, '*'];
end

if nargin < 3 || isempty(template)
    template = 'self';
end
if strcmp(template, 'self')
    boldext = ['_' template];
elseif strcmp(template, 'fsaverage')
    boldext = '_fsavg';
end


%% Identify all sessions (folders) match sessStr
sess_dir = dir(fullfile(HCP_path, sessStr));

if isempty(sess_dir)
    error('No sessions were found for %s in %s.', sessStr, HCP_path);
end

sessList = {sess_dir.name};
nSess = numel(sessList);

% the directory structure is saved in 'HCP/FreeSurfer'
FS_path = fullfile(HCP_path, 'FreeSurfer');

% create subjects/
subjects_path = fullfile(FS_path, 'subjects');
if ~exist(subjects_path, 'dir'); mkdir(subjects_path); end

% link fsaverage in subjects/ to fsaverage in FREESURFER 6.0 (or 5.3)
if ~exist(fullfile(subjects_path, 'fsaverage'), 'dir') && strcmp(boldext, '_fsavg')
    fsaverage = fullfile(fshome_path, 'subjects', 'fsaverage');
    fscmd_fsaverage = sprintf('ln -s %s %s', fsaverage, subjects_path);
    system(fscmd_fsaverage);
end

for iSess = 1:nSess
    
    sessid = sessList{iSess};
    sess_path = fullfile(HCP_path, sessid);
    
    %% link recon-all data
    source_subjCode = fullfile(sess_path, 'T1w', sessid);
    target_subjCode = fullfile(subjects_path, sessid);
    if ~exist(target_subjCode, 'dir')
        fscmd_subjcodelink = sprintf('ln -s %s %s', source_subjCode, subjects_path);
        system(fscmd_subjcodelink);
    end
    
    %% copy functional data to preprocessed folder
    % make directory for preprocessed data folder
    this_prepro_path = fullfile(FS_path, 'PreProcessed', sessid);
    if ~exist(this_prepro_path, 'dir'); mkdir(this_prepro_path); end
    
    % source and target path
    source_func = fullfile(sess_path, 'MNINonLinear', 'Results');
    run_dir = dir(fullfile(source_func, 'tfMRI*'));
    runName_cell = {run_dir.name};
        
    % copy functional data to preprocessed/
    cellfun(@(x) copyfile(fullfile(source_func, x, [x '_native.nii.gz']), ...
        fullfile(this_prepro_path, [x '_native.nii.gz'])), runName_cell);
    
    %% copy and rename from preprocessed folder to functional_data_'template'
    % make directory for the functional data
    func_path = fullfile(FS_path, ['functional_data' boldext]);
    subjCode_bold = [sessid boldext];
    subjCode_path = fullfile(func_path, subjCode_bold);
    this_func_path = fullfile(subjCode_path, 'bold');
    if ~exist(this_func_path, 'dir'); mkdir(this_func_path); end
    
    % create folders for each run
    runCode_cell = arrayfun(@(x) num2str(x, '%03d'), 1:numel(runName_cell), 'uni', false);
    cellfun(@(x) mkdir(this_func_path, x), runCode_cell);
    
    % save the run code and names in a txt file
    writetable(table(runCode_cell', runName_cell'), fullfile(this_func_path, ...
        'run_info.txt'), 'WriteVariableNames', false);
    
    % copy and rename the functional data file
    cellfun(@(x, y) copyfile(fullfile(source_func, x, [x '_native.nii.gz']), ...
        fullfile(this_func_path, y, 'f.nii.gz')), runName_cell, runCode_cell);
    
    %% create other files
    % create sessid 
    fs_createfile(fullfile(subjCode_path, 'sessid'), subjCode_bold);
    % create subjectname
    fs_createfile(fullfile(subjCode_path, 'subjectname'), sessid);
    
    %% Project functional data to the template
    wd_backup = pwd;
    
    % set the enviorment variable SUBJECTS_DIR
    setenv('SUBJECTS_DIR',subjects_path);
    
    cd(func_path);
    fscmd_prepro_run = sprintf(['preproc-sess -s %s -fsd bold'...
        ' -surface %s lhrh -mni305 -fwhm 0 -per-run -force'],...
        subjCode_bold, template);
    system(fscmd_prepro_run);
    
    cd(wd_backup);

    
end

end