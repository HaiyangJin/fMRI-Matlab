function FS = fs_subjdir(structPath, strPattern)
% function FS = fs_subjdir(structPath)
% This function set up 'SUBJECTS_DIR' and gather some information from FreeSurfer.
%
% Input:
%    structPath     <string> path to $SUBJECTS_DIR folder in FreeSurfer.
%    strPattern     <string> string pattern used to identify subject
%                    folders.
%
% Output:
%    FS             a struct contains FreeSurfer information
%
% Created and updated by Haiyang Jin (16-Jan-2020)

% get the enviorment variables on FreeSurfer
FS.homedir = getenv('FREESURFER_HOME');

% Default path to SUBJECTS_DIR
if nargin < 1 || isempty(structPath)
    structPath = getenv('SUBJECTS_DIR');
else
    setenv('SUBJECTS_DIR', structPath);
end

if nargin < 2 || isempty(strPattern)
    strPattern = '';
end

% set the subjects folder
FS.structPath = structPath;

% subject code information
subjDir = dir(fullfile(FS.structPath, strPattern));
subjDir = subjDir([subjDir.isdir]);  % only keep folders
FS.subjDir = subjDir(~ismember({subjDir.name}, {'.', '..'})); % remove . and ..
FS.subjList = {FS.subjDir.name};
FS.nSubj = numel(FS.subjList);

end
