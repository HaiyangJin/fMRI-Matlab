function sessStr = fs_hcp_projname(hcpPath)
% This function use the most frequent strings in hcpPath as the project
% name (or the prefix of session names)
%
% Inputs:
%    hcpPath       path to the HCP results ('Path/to/HCP/') [Default is the
%                   current working directory]
% Output:
%    sessStr        the project name or the prefix of session names
%
% Created by Haiyang Jin (5/01/2020)

if nargin < 1 || isempty(hcpPath)
    hcpPath = '.';
end

% all the folders in HCP path
tmpSessDir = dir(hcpPath);
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