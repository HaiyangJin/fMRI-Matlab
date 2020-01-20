function Norig = fs_Norig(subjCode)
% This function get the Norig matrix from FreeSurfer. It runs FreeSurface
% commands, so please make sure you set up FreeSurfer and Matlab properly.
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems 
% Different from Torig, Norig for each participants should be different.
%
% Created by Haiyang Jin (13/11/2019)


if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end

% Obtain the subjects folder path
structPath = getenv('SUBJECTS_DIR');

% define the path for orig.mgz
origFile = [structPath subjCode filesep 'mri' filesep 'orig.mgz'];

% create the freesurfer command
fscmd = sprintf('mri_info --vox2ras %s', origFile);

% run the command
[~, cmdout] = system(fscmd);

Norig = str2num(cmdout); %#ok<ST2NM>

