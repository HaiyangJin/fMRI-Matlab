function outpoints = selfras2fsavg(inpoints, subjCode)
% This functions converts self surface (vertex) RAS to MNI305 (fsaverage) RAS by
% following https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems
% (2).
%
% Created by Haiyang Jin (13/11/2019)

if ~exist('subjCode', 'var') || isempty(subjCode)
    error('Please input the subject code.');
end

% load the TalXFM file for this subject
taldir = [getenv('SUBJECTS_DIR') filesep subjCode filesep 'mri' filesep ...
    'transforms' filesep 'talairach.xfm'];
[~, talXFM] = system(sprintf('cat %s', taldir));

spaces = find(isspace(talXFM), 13, 'last');
talMat = str2num(talXFM(spaces(1): spaces(13))); %#ok<ST2NM>

% load Torig and Norig
Torig = fs_Torig(subjCode);
Norig = fs_Norig(subjCode);

% converting RAS
inRAS = [inpoints, 1];
outRAS = talMat * Norig / Torig * inRAS';

outpoints = outRAS';












