function FS = fs_subjdir(subjectsPath)
% function FS = fs_subjdir(subjectsPath)
% This function set up 'SUBJECTS_DIR' and gather some information from FreeSurfer.
%
% Input:
%    subjectsPath   path to subjects/ folder in FreeSurfer
%
% Output:
%    FS             a struct contains FreeSurfer information
%
% Created and updated by Haiyang Jin (16-Jan-2020)

% get the enviorment variables on FreeSurfer
FS.homedir = getenv('FREESURFER_HOME');

% Default path to FreeSurfer
if nargin < 1 || isempty(subjectsPath)
    subjectsPath = getenv('SUBJECTS_DIR');
else
    setenv('SUBJECTS_DIR', subjectsPath);
end

% set the subjects folder
FS.subjects = subjectsPath;

% hemisphere information
FS.hemis = {'lh', 'rh'};
FS.nHemi = numel(FS.hemis);

% subject code information
subjdir = dir(FS.subjects);
subjdir = subjdir([subjdir.isdir]);  % only keep folders
FS.subjdir = subjdir(~ismember({subjdir.name}, {'.', '..'})); % remove . and ..
FS.subjList = {FS.subjdir.name};
FS.nSubj = numel(FS.subjList);

end
