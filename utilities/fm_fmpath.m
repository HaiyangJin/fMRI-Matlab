function fmpath = fm_fmpath()
% fmpath = fm_fmpath()
%
% Get where fMRI-Matlab is stored. 
%
% Output:
%     fmpath     <str> path to the fMRI-Matlab Toolbox folder. 
%
% Created by Haiyang Jin (2023-April-26)

fmpath = fileparts(fileparts(mfilename('fullpath')));

end