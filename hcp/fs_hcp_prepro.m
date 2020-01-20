function fs_hcp_prepro(hcpPath, projString, template, linkT1)
% This function creates directory structure for analyses in FreeSurfer for
% results obtained from Human Connectome Project pipeline.
%
% Inputs:
%    HCP_path       path to the HCP results ('Path/to/HCP/') [Default is the
%                   current working directory]
%    projString     strings (or prefix) for session information (e.g.,
%                   'faceword' is the prefix for 'faceword01', 'faceword02',
%                   'faceword03'. sessStr will help to identify all the
%                   session folders. In order to perform this
%                   transformation for only one session, just set the sessStr
%                   as the full name of the session name (e.g., 'faceword01').
%    template       template used for projecting functional data ('self' or
%                   'fsaverage')
%    linkT1         [logical] 1: link the T1 for all subjects. 0: copy the
%                   T1 data for all subjects.
% Output:
%    a subfolder called FreeSurfer is built in HCP/. It contains the
%    directory structure (but not the structure data) for analyses in
%    FreeSurfer.
% Dependency:
%    FreeSurfer   (Please make sure FreeSurfer is installed and sourced properly.)
%
% Created by Haiyang Jin (5-Jan-2020).

% get the environment variable 
fshomePath = getenv('FREESURFER_HOME');
if isempty(fshomePath)
    error('Please make sure FreeSurfer is installed and sourced properly.');
end

if nargin < 1 || isempty(hcpPath)
    hcpPath = pwd;
end

if nargin < 2 || isempty(projString) || strcmp(projString, '.')
    projString = fs_hcp_projname(hcpPath);
end
% add '*' if last letter is not '*'
if projString(end) ~= '*' && ~strcmp(projString, '.')
    projString = [projString, '*'];
end

if nargin < 3 || isempty(template)
    template = 'self';
end
boldext = fs_template2boldext(template);

% link or copy the recon-all outputs
if nargin < 4 || isempty(linkT1)
    linkT1 = 1;
end


%% Identify all sessions (folders) match sessStr
hcpDir = dir(fullfile(hcpPath, projString));

if isempty(hcpDir)
    error('No sessions were found for %s in %s.', projString, hcpPath);
end

hcpList = {hcpDir.name};
nSubj = numel(hcpList);

% the directory structure is saved in 'HCP/FreeSurfer'
fsPath = fullfile(hcpPath, 'FreeSurfer');

% create subjects/
structPath = fullfile(fsPath, 'subjects');
if ~exist(structPath, 'dir'); mkdir(structPath); end
fs_subjdir(structPath);  % set 'SUBJECTS_DIR'

% link fsaverage in subjects/ to fsaverage in FREESURFER 6.0 (or 5.3)
if ~exist(fullfile(structPath, 'fsaverage'), 'dir') && strcmp(boldext, '_fsavg')
    fsaverage = fullfile(fshomePath, 'subjects', 'fsaverage');
    if linkT1 % link file
        fscmd_fsaverage = sprintf('ln -s %s %s', fsaverage, structPath);
        system(fscmd_fsaverage);
    else % copy file
        copyfile(fsaverage, fullfile(structPath, 'fsaverage'));
    end     
end

for iSubj = 1:nSubj
    
    % this session
    thisSubj = hcpList{iSubj};
    thisPath = fullfile(hcpPath, thisSubj);
    
    %% link (or copy) recon-all data
    targetSubjCode = fullfile(structPath, thisSubj);
    sourceSubjCode = fullfile(thisPath, 'T1w', thisSubj); % use relative directory
    if ~exist(targetSubjCode, 'dir')
        if linkT1 % link folder
            fscmd_linksubjdir = sprintf('ln -s %s %s', sourceSubjCode, structPath);
            system(fscmd_linksubjdir);
        else % copy folder
            copyfile(sourceSubjCode, targetSubjCode);
        end
    end
    
    %% copy functional data to preprocessed folder
    % make directory for preprocessed data folder
    thisPreproPath = fullfile(fsPath, 'PreProcessed', thisSubj);
    if ~exist(thisPreproPath, 'dir'); mkdir(thisPreproPath); end
    
    % source and target path
    sourceFunc = fullfile(thisPath, 'MNINonLinear', 'Results');
    runDir = dir(fullfile(sourceFunc, 'tfMRI*'));
    runNameCell = {runDir.name};
        
    % copy functional data to preprocessed/
    cellfun(@(x) copyfile(fullfile(sourceFunc, x, [x '_native.nii.gz']), ...
        fullfile(thisPreproPath, [x '_native.nii.gz'])), runNameCell);
    
    %% copy and rename from preprocessed folder to functional_data_'template'
    % make directory for the functional data
    funcPath = fullfile(fsPath, ['functional_data' boldext]);
    sessCode = [thisSubj boldext];
    sessPath = fullfile(funcPath, sessCode);
    thisBoldPath = fullfile(sessPath, 'bold');
    if ~exist(thisBoldPath, 'dir'); mkdir(thisBoldPath); end
    
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
    fs_createfile(fullfile(sessPath, 'sessid'), sessCode);
    % create subjectname
    fs_createfile(fullfile(sessPath, 'subjectname'), thisSubj);
    
    %% Project functional data to the template
    wdBackup = pwd;
        
    cd(funcPath);
    fscmd_prepro_run = sprintf(['preproc-sess -s %s -fsd bold'...
        ' -surface %s lhrh -mni305 -fwhm 0 -per-run -force'],...
        sessCode, template);
    system(fscmd_prepro_run);
    
    cd(wdBackup);

    
end

end