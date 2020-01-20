function outpoints = mni2fsavg(inpoints)
% 
% This function converts MNI152 to fsaverage (MNI305).
% Parameters are obtained from FreeSurf website.
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems (check 8b)
%
% Usage: outpoints = mni2fsavg([R A S]);
%
% Created by Haiyang Jin (13/11/2019)

inRAS = [inpoints 1]';

% matrix obtained from FreeSurf website
matrix = [1.0022    0.0071   -0.0177    0.0528;
         -0.0146    0.9990    0.0027   -1.5519;
          0.0129    0.0094    1.0027   -1.2012];

% calculate the new RAS
outRAS = matrix * inRAS;

% transpose the out RAS
outpoints = outRAS';

end