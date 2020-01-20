function outpoints = selfras2scanras(inpoints, subjCode)
% This function converts self RAS to scanner RAS (not the fsaverage RAS or
% MNI305 RAS) by following
% https://surfer.nmr.mgh.harvard.edu/fswiki/CoordinateSystems (3).
%
% Created by Haiyang Jin (13/11/2019)

% Obtain Norig and Torig
Norig = fs_Norig(subjCode);
Torig = fs_Torig(subjCode);

% Converting 
inRAS = [inpoints, 1];
outRAS = Norig / Torig * inRAS';

outpoints = outRAS';

outpoints = outpoints(1:3);

end