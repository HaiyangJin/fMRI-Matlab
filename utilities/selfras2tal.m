function outpoints = selfras2tal(inpoints, subjCode)
% DEPRECATED: use fs_ras2tal.m instead.
% This function converts self RAS to Talairach RAS. 
%
% Created by Haiyang Jin (13/11/2019)

% from self RAS (through Voxel RAS) to MNI305 RAS (fsaverage)
outpoints1 = selfras2fsavg(inpoints, subjCode);

% from MNI305 RAS (fsaverage) to Talairach
outpoints = fsavg2tal(outpoints1);