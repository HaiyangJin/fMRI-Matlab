function funcdir = hcp_funcdir(subjCode)
% funcdir = hcp_funcdir(subjCode)
%
% Get the path to the functional results. If <subjCode> is empty, it
% returns the relative path. If <subjCode> is not empty and exist, it
% returns the full path.
%
% Inputs:
%    subjCode      <string> subject code.
%
% Output:
%    funcdir       <string> path to the functional data.
%
% Created by Haiyang Jin (2021-09-28)

if ~exist('subjCode', 'var') 
    subjCode = "";
end

if isempty(subjCode)
    funcdir = fullfile("MNINonLinear", "Results");
    warning('funcdir is a relative path as <subjCode> is empty.')
    return;
end

% make sure HCP_DIR is set 
if isempty(getenv("HCP_DIR"))
    error('Please use "hcp_setdir()" to set the HCP directory.');
end

% make sure <subjCode> directory exists
assert(logical(exist(fullfile(getenv("HCP_DIR"), subjCode), 'dir')), ...
    'Cannot find subject (%s) in the project directory (%s).', ...
    subjCode, getenv("HCP_DIR"));

funcdir = fullfile(getenv("HCP_DIR"), subjCode, "MNINonLinear", "Results");

end