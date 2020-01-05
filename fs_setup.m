function FS = fs_setup
% This function gather some FreeSurfer information

% get the enviorment variables on FreeSurfer
FS.homedir = getenv('FREESURFER_HOME');

if isempty(FS.homedir)
    error('Please make sure FreeSurfer is installed and sourced properly.');
end

FS.subjects = getenv('SUBJECTS_DIR');

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
