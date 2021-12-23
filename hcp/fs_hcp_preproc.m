function fs_hcp_preproc(hcpDir, template, varargin)
% fs_hcp_preproc(hcpDir, template, varargin)
%
% This function creates directory structure for analyses in FreeSurfer for
% results obtained from Human Connectome Project pipeline. The steps
% include:
%    (0) convert functional data in MNI space to native space (this step is
%        not included in this function; please refer to hcp_mni2native);
%    (1) link (or copy) T1 directory ("$SUBJECTS_DIR");
%    (2) create FreeSurfer-format directories for functional data;
%    (3) copy and rename the functional data (in volume);
%    (4) project functional data to 'fsaverage' (or 'self') surface with
%        preprocessing of motion correction and brain-mask creation
%        (default in FreeSurfer).
%
% Inputs:
%    hcpDir           <str> path to the HCP results ('Path/to/HCP/')
%                      [Default is "$HCP_DIR"].
%    template         <str> template used for projecting functional data
%                      ('self' or 'fsaverage').
%
% Varargin:
%    .funcext         <str> strings to be added at the end of
%                      functionals folder name.
%    .linkt1          <boo> 1: link the T1 for all subjects. 0: copy the
%                      T1 data for all subjects.
%    .smooth          <int> smoothness.
%    .extracmd        <str> extra command strings used for preproc-sess.
%
% Output:
%    a folder called FreeSurfer is created in the same folder with the same
%    level of hcpDir/. It contains the directory structure (but not the
%    anatomy data) for analyses in FreeSurfer.
%
% Dependency:
%    FreeSurfer   (Please make sure FreeSurfer is installed and sourced properly.)
%
% Created by Haiyang Jin (2020-01-05).

% get the environment variable
fshomePath = getenv('FREESURFER_HOME');
if isempty(fshomePath)
    error('Please make sure FreeSurfer is installed and sourced properly.');
end

if ~exist('hcpDir', 'var') || isempty(hcpDir)
    hcpDir = hcp_dir;
end

if ~exist('template', 'var') || isempty(template)
    template = 'fsaverage';
    warning('The template was not specified and fsaverage will be used by default.');
elseif ~ismember(template, {'fsaverage', 'self'})
    error('The template has to be ''fsaverage'' or ''self'' (not ''%s'').', template);
end

defaultOpts = struct(...
    'funcext', '', ...
    'linkt1', 1, ...
    'smooth', 0, ...
    'extracmd', '');
opts = fm_mergestruct(defaultOpts, varargin{:});


%% Identify all sessions (folders) match sessStr
% the directory structure is saved in 'HCP/../FreeSurfer'
fsPath = fullfile(hcpDir, '..', 'FreeSurfer');

% create subjects/
struDir = fullfile(fsPath, 'subjects');
fm_mkdir(struDir);
fs_subjdir(struDir);  % set 'SUBJECTS_DIR'

% link fsaverage in subjects/ to fsaverage in FREESURFER 7.1 (or 6.0)
if ~exist(fullfile(struDir, 'fsaverage'), 'dir') && strcmp(template, 'fsaverage')
    fsaverage = fullfile(fshomePath, 'subjects', 'fsaverage');
    if opts.linkt1 % link file
        fscmd_fsaverage = sprintf('ln -s %s %s', fsaverage, struDir);
        system(fscmd_fsaverage);
    else % copy file
        copyfile(fsaverage, fullfile(struDir, 'fsaverage'));
    end
end
% link other subjects
fs_hcp_linksubjdir(struDir, hcpDir, opts.linkt1);

[hcpList, nSubj] = hcp_subjlist(hcpDir);
for iSubj = 1:nSubj
    
    % this session
    thisSubj = hcpList{iSubj};
    thisPath = fullfile(hcpDir, thisSubj);
    
    %% copy functional data to preprocessed folder
    % make directory for preprocessed data folder
    thisPreproPath = fullfile(fsPath, 'PreProcessed', thisSubj);
    fm_mkdir(thisPreproPath);
    
    % source and target path
    sourceFunc = fullfile(thisPath, 'MNINonLinear', 'Results');
    runDir = dir(fullfile(sourceFunc, '*fMRI*'));
    runNameCell = {runDir.name};
    
    % copy functional data to preprocessed/
    cellfun(@(x) copyfile(fullfile(sourceFunc, x, [x '_native.nii.gz']), ...
        fullfile(thisPreproPath, [x '_native.nii.gz'])), runNameCell);
    
    %% copy and rename from preprocessed folder to functional_data_'template'
    % make directory for the functional data
    funcDir = fullfile(fsPath, ['functional_data' opts.funcext]);
    sessCode = [thisSubj '_' template];
    sessPath = fullfile(funcDir, sessCode);
    thisBoldPath = fullfile(sessPath, 'bold');
    fm_mkdir(thisBoldPath);
    
    % create folders for each run
    runCodeCell = arrayfun(@(x) num2str(x, '%03d'), 1:numel(runNameCell), 'uni', false);
    cellfun(@(x) mkdir(thisBoldPath, x), runCodeCell);
    
    % save the run code and names in a txt file
    RunCode = runCodeCell';
    RunName = runNameCell';
    writetable(table(RunCode, RunName), fullfile(thisBoldPath, 'run_info.txt'));
    
    % copy and rename the functional data file
    cellfun(@(x, y) copyfile(fullfile(sourceFunc, x, [x '_native.nii.gz']), ...
        fullfile(thisBoldPath, y, 'f.nii.gz')), runNameCell, runCodeCell);
    
    %% create other files
    % create sessid
    fm_mkfile(fullfile(sessPath, 'sessid'), sessCode);
    % create subjectname
    fm_mkfile(fullfile(sessPath, 'subjectname'), thisSubj);
    
    %% Project functional data to the template
    wdBackup = pwd;
    cd(funcDir);

    % project functional data onto surface
    fs_preproc(sessCode, opts.smooth, template, opts.extracmd);    
    cd(wdBackup);    
    
end

end