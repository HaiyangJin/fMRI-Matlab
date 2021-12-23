function outpoints = fs_self2fsavg(inpoints, subjCode)
% outpoints = fs_self2fsavg(inpoints, subjCode)
%
% This functions converts self surface (or volume) RAS [in real world] to 
% MNI305 (fsaverage) RAS by following 
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems (2).
%
% [It is not the Talairach coordinates shown in tksurfer (surface % or 
% volume). Talairach shown in tksurfer is use fs_self2tal.m] 
%
% In TkSurfer:
%    Vertex MNI Talairach = fs_self2fsavg(Vertex RAS, subjCode);
%    [vertex RAS should be the coordiantes on ?h.orig]
% In TkMedit:
%    MNI Talairach = fs_self2fsavg(Volume RAS, subjCode);
%
% Inputs:
%    inpoints        <numeric array> RAS on self surface [real world].
%    subjCode        <string> subject code in $SUBJECTS_DIR.
%
% Output:
%    outpoints       <numeric array> cooridnates on fsaverage (MNI305 or
%                     MNI Talairach).
%
% Created by Haiyang Jin (13-Nov-2019)
%
% See also:
% fs_self2tal; mni2tal

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end

%% Load the TalXFM file for this subject
taldir = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'mri', 'transforms', 'talairach.xfm');
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