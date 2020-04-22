function Torig = fs_Torig(subjCode, struPath)
% Torig = fs_Torig([subjCode='fsaverage', struPath])
%
% This function get the Torig (TkSurfer orig.mgz) matrix from FreeSurfer.  
% The output matrix is obtained from "mri_info --vox2ras-tkr orig.mgz".
% (note: this is the same for all orig volumes).
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems
% Torig matrix should be the same for all participants.
%
% It runs FreeSurface commands, so please make sure you set up FreeSurfer
% and Matlab properly.
%
% Input:
%    subjCode        <string> subject code in struPath. Default is empty.
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    Torig           <numeric matrix> Torig matrix is the vox2vox matrix
%                     from VoxCRS (orig.mgz) to Vertex RAS (in tksurfer
%                     tools window).
%
% Created by Haiyang Jin (13-Nov-2019)

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

% define the path to orig.mgz
origFile = fullfile(struPath, subjCode, 'mri', 'orig.mgz');

% Create and run the FreeSurfer command
fscmd = sprintf('mri_info --vox2ras-tkr %s', origFile);
[isnotok, cmdout] = system(fscmd);

if isnotok
    warning('FreeSurfer commands (mri_info) failed and Torig is empty.');
end

%% Convert the output to a numeric mattrix
strs = strsplit(cmdout);
strs(cellfun(@isempty, strs)) = [];  % remove empty cells

nums = cellfun(@str2double, strs);

Torig = reshape(nums, 4, 4)';

end