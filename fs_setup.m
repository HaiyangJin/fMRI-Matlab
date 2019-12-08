function FS=fs_setup

% get the enviorment variables on FreeSurfer
FS.homedir = getenv('FREESURFER_HOME');
FS.subjects = getenv('SUBJECTS_DIR');
FS.hemis = {'lh', 'rh'};
FS.nHemi = numel(FS.hemis);
