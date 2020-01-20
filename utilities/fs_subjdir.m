function FS = fs_subjdir(structPath)
% function FS = fs_subjdir(structPath)
% This function set up 'SUBJECTS_DIR' and gather some information from FreeSurfer.
%
% Input:
%    structPath   path to subjects/ folder in FreeSurfer
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

% set the subjects folder
FS.structPath = structPath;

% hemisphere information
FS.hemis = {'lh', 'rh'};
FS.nHemi = numel(FS.hemis);

% subject code information
subjDir = dir(FS.structPath);
subjDir = subjDir([subjDir.isdir]);  % only keep folders
FS.subjDir = subjDir(~ismember({subjDir.name}, {'.', '..'})); % remove . and ..
FS.subjList = {FS.subjDir.name};
FS.nSubj = numel(FS.subjList);

end
