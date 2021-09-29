function sessStr = hcp_projname(hcpDir)
% sessStr = hcp_projname(hcpDir)
%
% This function uses the most frequent strings in hcpDir as the project
% name (or the prefix of session names)
%
% Inputs:
%    hcpDir        <string> path to the HCP results ('Path/to/HCP/').
%                   [Default is "$HCP_DIR"].
% Output:
%    sessStr       <string> the project name or the prefix of session
%                    names.
%
% Created by Haiyang Jin (2020-01-05)

if nargin < 1 || isempty(hcpDir)
    hcpDir = '';
end
hcpDir = hcp_dir(hcpDir);

% all the folders in HCP path
tmpSessDir = dir(hcpDir);
tmpSessDir(startsWith({tmpSessDir.name}, '.')) = [];  % remove folders starts with '.'
tmpSessList = {tmpSessDir.name};

% the string parts of all folder names
numericParts =  regexp(tmpSessList, '\d+', 'match');
stringParts = cellfun(@(x, y) erase(x, y), tmpSessList, numericParts, 'uni', false);

% information of string parts
[uc, ~, idc] = unique(stringParts) ;
counts = histcounts(idc);

% the most frequent string will be used as the prefix
[~, whichStr] = max(counts);
sessStr = uc{whichStr};

end