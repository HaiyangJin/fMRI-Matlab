function origMat = fs_TNorig(subjCode, TN, struDir)
% origMat = fs_Torig([subjCode='fsaverage', TN, struDir])
%
% This function get the Torig (TkSurfer or surface Vox2RAS) or Norig 
% (Native or Scanner Vox2RAS) matrix from FreeSurfer.  
% The Torig matrix is obtained from "mri_info --vox2ras-tkr orig.mgz" (this
% is the same for all orig volumes). And the Norig matrix is obtained from
% "mri_info --vox2ras orig.mgz" (this should be different for each subject.)
%
% Torig (TkSurfer or surface Vox2RAS) is matrix for converting from
% orig.mgz (scanner CRS) to surface in real world (surface RAS). 
% In tkSurfer (or tkMedit):
%    Vertex RAS (or Volume RAS) = Torig * Volume index; 
% 
% Norig (Native or Scanner Vox2RAS) is matrix for converting from orig.mgz 
% (scanner CRS) to volume in real word [Scanner XYZ (or RAS)]. 
% CRS: column; row; slice.
%
% More see: 
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems
%
% It runs FreeSurface commands, so please make sure you set up FreeSurfer
% and Matlab properly.
%
% Input:
%    subjCode        <str> subject code in $SUBJECTS_DIR. Default is 'fsaverage'.
%    TN              <str> 't' (for Torig) or 'n' (for Norig). Default
%                     is 't'. 
%    struDir         <str> $SUBJECTS_DIR.
%
% Output:
%    origMat         <num matrix> origMat matrix is the vox2vox matrix
%                     from VoxCRS (orig.mgz) to Vertex RAS in real world 
%                     (in tksurfer tools window) [when TN is 't'], or from 
%                     VoxCRS to VoxXYZ (VoxRAS) in real world.
%
% Created by Haiyang Jin (13-Nov-2019)

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
end
if ~exist('TN', 'var') || isempty(TN)
    TN = 't';
end
if ~exist('struDir', 'var') || isempty(struDir)
    struDir = getenv('SUBJECTS_DIR');
end

% define the path to orig.mgz
origFile = fullfile(struDir, subjCode, 'mri', 'orig.mgz');

% Create and run the FreeSurfer command
if strcmpi(TN, 't') % for Torig
    TNstr = '-tkr';
elseif strcmpi(TN, 'n') % for Norig
    TNstr = '';
else
    error('''TN'' has to be ''t'' (for Torig) or ''n'' (for Norig) [not %s].', TN);
end
    
fscmd = sprintf('mri_info --vox2ras%s %s', TNstr, origFile);
[isnotok, cmdout] = system(fscmd);

if isnotok
    warning('FreeSurfer commands (mri_info) failed and Torig is empty.');
end

%% Convert the output to a numeric mattrix
strs = strsplit(cmdout);
strs(cellfun(@isempty, strs)) = [];  % remove empty cells

nums = cellfun(@str2double, strs);

origMat = reshape(nums, 4, 4)';

end