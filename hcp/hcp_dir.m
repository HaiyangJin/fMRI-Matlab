function hcpDir = hcp_dir(hcpDir)
% hcpDir = hcp_dir(hcpDir)
%
% Set hcpDir as a global environment "HCP_DIR". hcpDir's sub-directory
% should be subject folders.
%
% Input:
%    hcpDir      <string> full path to the project direcotry that stores
%                 data for all participants.
% Output:
%    hcpDir      <string> same as the input.
%    subjList    <cell str> list of subject codes.
%
% Created by Haiyang Jin (2021-09-28)

if nargin < 1 || isempty(hcpDir)
    if ~isempty(getenv("HCP_DIR"))
        hcpDir = getenv("HCP_DIR");
        return;
    end
    error('Please input the project directory.')
end

% make sure the hcpDir exists
assert(logical(exist(hcpDir, 'dir')), 'Cannot find the directory: \n%s...', hcpDir);
setenv("HCP_DIR", hcpDir);

end