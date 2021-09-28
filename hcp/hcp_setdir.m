function projDir = hcp_setdir(projDir)
% projDir = hcp_setdir(projDir)
%
% Set projDir as a global environment "HCP_DIR".
%
% Input:
%    projDir     <string> full path to the project direcotry that stores
%                 data for all participants.
% Output:
%    projDir     <string> same as the input.
%
% Created by Haiyang Jin (2021-09-28)

if nargin < 1
    error('Please input the project directory.')
end

setenv("HCP_DIR", projDir);

end