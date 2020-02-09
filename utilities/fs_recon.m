function fs_recon(t1File, subjCode)
% This function run 'recon-all' in FreeSurfer
%
% Inputs:
%     t1File       <string> the path to the T1 file
%     subjCode     <string> subject code
%
% Created by Haiyang Jin (6-Feb-2020)

fscmd = sprintf('recon-all -i %s -s % -all', t1File, subjCode);
system(fscmd);