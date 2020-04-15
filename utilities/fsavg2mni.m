function outpoints = fsavg2mni(inpoints)
% outpoints = fsavg2mni(inpoints)
% 
% This function converts fsaverage (MNI305) to MNI152.
% Parameters are obtained from FreeSurf website.
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems (check 8)
%
% Input:
%    inpoints    <numeric array> a P x 3 matrix. Each row is one point and
%                 the three columns are [R A S].
% Output:
%    outpoints   <numeric array> a P x 3 matrix in MNI152 space.
%
% Usage: outpoints = fsavg2mni([R A S]);
%
% Created by Haiyang Jin (13-Nov-2019)

inRAS = horzcat(inpoints, ones(size(inpoints, 1), 1))';

% matrix obtained from FreeSurf website
matrix = [0.9975   -0.0073    0.0176   -0.0429;
          0.0146    1.0009   -0.0024    1.5496;
         -0.0130   -0.0093    0.9971    1.1840];

% calculate the new RAS
outRAS = matrix * inRAS;

% transpose the out RAS
outpoints = outRAS';

end