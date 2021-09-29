function fs_hcp_linksubjdir(structPath, hcpDir, linkT1)
% fs_hcp_linksubjdir(structPath, hcpDir, linkT1)
%
% This function re-link the SUBJECTS_DIR after the output from HCP is
% downloaded to local storage.
%
% Input:
%     structPath      <string> '$SUBJECTS_DIR'
%     hcpDir          <string> the full path to HCP/ folder, which stores
%                       subject folders.
%     linkT1          <logical> 1 (default): link files. 0: copy files.
% 
% Output:
%     re-link (or copy) the folders in SUBJECTS_DIR
%
% Created by Haiyang Jin (20-Jan-2020)

% gather information about 'SUBJECTS_DIR'
if ~exist('structPath', 'var')  || isempty(structPath)
    structPath = fs_subjdir;
end
% path to SUBJECTS_DIR

% obtain the  the hcpDir (if empty) based on structPath
if ~exist('hcpDir', 'var')  || isempty(hcpDir)
    hcpDir = hcp_dir;
end
subjList = hcp_subjlist(hcpDir);

% link file by default
if ~exist('linkT1', 'var')  || isempty(linkT1)
    linkT1 = 1;
end

for iSubj = 1:length(subjList)
    
    thisSubj = subjList{iSubj};
    
    sourceSubjCode = fullfile(hcpDir, thisSubj, 'T1w', thisSubj);
    targetSubjCode = fullfile(structPath, thisSubj);
    
    % link (or copy) recon-all data
    if linkT1 % link files
        delete(targetSubjCode);  % delete the old folder
        cmd_link = sprintf('ln -s %s %s', sourceSubjCode, structPath);
        system(cmd_link);
    elseif ~linkT1
        copyfile(sourceSubjCode, targetSubjCode);
    end
    
end