function [subjList, nSubj] = bids_subjlist(substr, bidsDir)
% [subjList, nSubj] = bids_subjlist(substr, bidsDir)
%
% Get subject codes in <bidsDir>.
%
% Inputs:
%    substr        <str> wildcard to identify subject folders. Default is
%                   'sub-*'.
%    bidsDir       <str> the BIDS directory. Default is bids_dir().
%
% Outputs:
%    subjList      <cell str> list of subject codes.
%    nSubj         <int> number of subjects.
%
% Created by Haiyang Jin (2021-10-13)

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

% the str should start with 'sub-' and ends with '*'
if ~exist('substr', 'var') || isempty(substr)
    substr = 'sub-*';
elseif ~endsWith(substr, '*')
    substr = [substr '*'];
end
if ~startsWith(substr, 'sub-')
    substr = ['sub-', substr];
end

% get the list of subjects
subjdir = dir(fullfile(bidsDir, substr));
subjList = {subjdir.name};

nSubj = length(subjList);

end