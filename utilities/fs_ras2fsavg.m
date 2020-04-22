function outpoints = fs_ras2fsavg(inpoints, subjCode, struPath)
% outpoints = fs_ras2fsavg(inpoints, subjCode, [struPath])
%
% This functions converts self surface (or volume) RAS [in real world] to 
% MNI305 (fsaverage) RAS [shown as MNI Talairach in tksurfer (surface 
% or volume)] by following 
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems (2).
%
% In TkSurfer:
%    Vertex MNI Talairach = fs_ras2fsavg(Vertex RAS, subjCode);
%    [vertex RAS should be the coordiantes on ?h.white (to be confirmed)]
% In TkMedit:
%    MNI Talairach = fs_ras2fsavg(Volume RAS, subjCode);
%
% Inputs:
%    inpoints        <numeric array> RAS on self surface [real world].
%    subjCode        <string> subject code in struPath.
%    struPath        <string> $SUBJECTS_DIR.
%
% Output:
%    outpoints       <numeric array> cooridnates on fsaverage (MNI305 or
%                     MNI Talairach).
%
% Created by Haiyang Jin (13-Nov-2019)

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
end

%% Load the TalXFM file for this subject
taldir = fullfile(struPath, subjCode, 'mri', 'transforms', 'talairach.xfm');
[~, talXFM] = system(sprintf('cat %s', taldir));

% split talXFM
strs = strsplit(talXFM, {' ', ';', '\n'});
strs(cellfun(@isempty, strs)) = [];  % remove empty cells

% convert strings to numeric array
nums = cellfun(@str2double, strs(end-11:end));
talMat =  reshape(nums, 4, 3)';

%% Convert to fsaverage (MNI305) [MNI Talariarch]
% load Torig and Norig
Torig = fs_TNorig(subjCode, 't');
Norig = fs_TNorig(subjCode, 'n');

% converting RAS
inRAS = horzcat(inpoints, ones(size(inpoints, 1), 1))';
outRAS = talMat * Norig / Torig * inRAS;

outpoints = outRAS';

end