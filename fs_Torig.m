function Torig = fs_Torig(subjCode)
% This function get the Torig matrix from FreeSurfer. It runs FreeSurface
% commands, so please make sure you set up FreeSurfer and Matlab properly.
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems 
% Torig matrix should be the same for all participants.
%
% Created by Haiyang Jin (13/11/2019)

if ~exist('subjCode', 'var') || isempty(subjCode); subjCode = 'fsaverage'; end

% obtain the subject folder path
subjectsdir = getenv('FUNCTIONALS_DIR');

% define the path to orig.mgz
orig_dir = [subjectsdir subjCode filesep 'mri' filesep 'orig.mgz'];

% create the FreeSurfer command
fscmd = sprintf('mri_info --vox2ras-tkr %s', orig_dir);

% Run the command
[~, cmdout] = system(fscmd);

Torig = str2num(cmdout); %#ok<ST2NM>

