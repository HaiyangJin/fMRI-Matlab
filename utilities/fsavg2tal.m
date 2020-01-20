function outpoints = fsavg2tal(inpoints)
% This function converts freesurfer (fsaverage or MNI305) to Talairach
%
% Created by Haiyang Jin (13/11/2019)

% from MNI305 (fsaverage) to MNI152
outpoints1 = fsavg2mni(inpoints);

% from MNI152 to tal
outpoints = mni2tal(outpoints1);