function fs_hcp_prepro(hcpPath, sessStr, template, linkT1)
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
%    linkT1         [logical] 1: link the T1 for all subjects. 0: copy the
%                   T1 data for all subjects.
% Output:
%    a subfolder called FreeSurfer is built in HCP/. It contains the
%    directory structure (but not the structure data) for analyses in
%    FreeSurfer.
% Dependency:
%    FreeSurfer   (Please make sure FreeSurfer is installed and sourced properly.)
%
% Created by Haiyang Jin (5/01/2020).

% get the environment variable 
fshomePath = getenv('FREESURFER_HOME');
if isempty(fshomePath)
    error('Please make sure FreeSurfer is installed and sourced properly.');
end

if nargin < 1 || isempty(hcpPath)
    hcpPath = pwd;
end

if nargin < 2 || isempty(sessStr) || strcmp(sessStr, '.')
    sessStr = fs_hcp_projname(hcpPath);
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

% link or copy the recon-all outputs
if nargin < 4 || isempty(linkT1)
    linkT1 = 1;
end


%% Identify all sessions (folders) match sessStr
sessDir = dir(fullfile(hcpPath, sessStr));

if isempty(sessDir)
    error('No sessions were found for %s in %s.', sessStr, hcpPath);
end

sessList = {sessDir.name};
nSess = numel(sessList);

% the directory structure is saved in 'HCP/FreeSurfer'
fsPath = fullfile(hcpPath, 'FreeSurfer');

% create subjects/
subjectsPath = fullfile(fsPath, 'subjects');
if ~exist(subjectsPath, 'dir'); mkdir(subjectsPath); end
fs_projectinfo(subjectsPath);  % set 'SUBJECTS_DIR'

% link fsaverage in subjects/ to fsaverage in FREESURFER 6.0 (or 5.3)
if ~exist(fullfile(subjectsPath, 'fsaverage'), 'dir') && strcmp(boldext, '_fsavg')
    fsaverage = fullfile(fshomePath, 'subjects', 'fsaverage');
    if linkT1 % link file
        fscmd_fsaverage = sprintf('ln -s %s %s', fsaverage, subjectsPath);
        system(fscmd_fsaverage);
    else % copy file
        copyfile(fsaverage, fullfile(subjectsPath, 'fsaverage'));
    end     
end

for iSess = 1:nSess
    
    % this session
    sessid = sessList{iSess};
    sessPath = fullfile(hcpPath, sessid);
    
    %% link (or copy) recon-all data
    sourceSubjCode = fullfile(sessPath, 'T1w', sessid);
    targetSubjCode = fullfile(subjectsPath, sessid);
    if ~exist(targetSubjCode, 'dir')
        if linkT1 % link folder
            fscmd_subjcodelink = sprintf('ln -s %s %s', sourceSubjCode, subjectsPath);
            system(fscmd_subjcodelink);
        else % copy folder
            copyfile(sourceSubjCode, targetSubjCode);
        end
    end
    
    %% copy functional data to preprocessed folder
    % make directory for preprocessed data folder
    thisPreproPath = fullfile(fsPath, 'PreProcessed', sessid);
    if ~exist(thisPreproPath, 'dir'); mkdir(thisPreproPath); end
    
    % source and target path
    sourceFunc = fullfile(sessPath, 'MNINonLinear', 'Results');
    runDir = dir(fullfile(sourceFunc, 'tfMRI*'));
    runNameCell = {runDir.name};
        
    % copy functional data to preprocessed/
    cellfun(@(x) copyfile(fullfile(sourceFunc, x, [x '_native.nii.gz']), ...
        fullfile(thisPreproPath, [x '_native.nii.gz'])), runNameCell);
    
    %% copy and rename from preprocessed folder to functional_data_'template'
    % make directory for the functional data
    funcPath = fullfile(fsPath, ['functional_data' boldext]);
    subjCodeBold = [sessid boldext];
    subjCodePath = fullfile(funcPath, subjCodeBold);
    thisFuncPath = fullfile(subjCodePath, 'bold');
    if ~exist(thisFuncPath, 'dir'); mkdir(thisFuncPath); end
    
    % create folders for each run
    runCodeCell = arrayfun(@(x) num2str(x, '%03d'), 1:numel(runNameCell), 'uni', false);
    cellfun(@(x) mkdir(thisFuncPath, x), runCodeCell);
    
    % save the run code and names in a txt file
    RunCode = runCodeCell';
    RunName = runNameCell';
    writetable(table(RunCode, RunName), fullfile(thisFuncPath, 'run_info.txt'));
    
    % copy and rename the functional data file
    cellfun(@(x, y) copyfile(fullfile(sourceFunc, x, [x '_native.nii.gz']), ...
        fullfile(thisFuncPath, y, 'f.nii.gz')), runNameCell, runCodeCell);
    
    %% create other files
    % create sessid 
    fs_createfile(fullfile(subjCodePath, 'sessid'), subjCodeBold);
    % create subjectname
    fs_createfile(fullfile(subjCodePath, 'subjectname'), sessid);
    
    %% Project functional data to the template
    wdBackup = pwd;
        
    cd(funcPath);
    fscmd_prepro_run = sprintf(['preproc-sess -s %s -fsd bold'...
        ' -surface %s lhrh -mni305 -fwhm 0 -per-run -force'],...
        subjCodeBold, template);
    system(fscmd_prepro_run);
    
    cd(wdBackup);

    
end

end