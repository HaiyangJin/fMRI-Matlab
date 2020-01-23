function fs_hcp_linksubjdir(structPath, hcpPath, isLinkT1)
% This function re-link the SUBJECTS_DIR after the output from HCP is
% downloaded to local storage.
%
% Input:
%     structPath       <string> 'SUBJECTS_DIR'
%     hcpPath          <string> the full path to HCP/ folder
%     isLinkT1         <logical> 1: link files. 0: copy files.
% Output:
%     re-link the folders in SUBJECTS_DIR
%
% Created by Haiyang Jin (20-Jan-2020)

% gather information about 'SUBJECTS_DIR'
if nargin < 1 || isempty(structPath)
    FS = fs_subjdir;
else
    FS = fs_subjdir(structPath);
end
% path to SUBJECTS_DIR
structPath = FS.structPath;

% set the hcpPath (if empty) based on structPath
if nargin < 2 || isempty(hcpPath)
    hcpPath = fullfile(structPath, '..');
end

% link file by default
if nargin < 3 || isempty(isLinkT1)
    isLinkT1 = 1;
end

for iSubj = 1:FS.nSubj
    
    thisSubj = FS.subjList{iSubj};
    
    sourceSubjCode = fullfile(hcpPath, thisSubj, 'T1w', thisSubj);
    targetSubjCode = fullfile(structPath, thisSubj);
    
    % link (or copy) recon-all data
    if isLinkT1 % link files
        fscmd_link = sprintf('ln -s %s %s', sourceSubjCode, structPath);
        system(fscmd_link);
    elseif ~isLinkT1
        copyfile(sourceSubjCode, targetSubjCode);
    end
    
end