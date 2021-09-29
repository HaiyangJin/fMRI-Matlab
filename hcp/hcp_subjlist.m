function [subjList, nSubj] = hcp_subjlist(hcpDir)
% [subjList, nSubj] = hcp_subjlist(hcpDir)
%
% Get subject codes in 'hcpDir'.
%
% Inputs:
%    hcpDir        <string> path to the HCP results ('Path/to/HCP/').
%                   [Default is "$HCP_DIR"].
%
% Outputs:
%    subjList      <cell str> list of subject codes.
%    nSubj         <int> number of subjects.
%
% Created by Haiyang Jin (2021-09-29)

if nargin < 1 || isempty(hcpDir)
    hcpDir = hcp_dir;
end

% get the list of subjects
subjdir = dir(fullfile(hcpDir, [hcp_projname, '*']));
subjList = {subjdir.name};

nSubj = length(subjList);

end