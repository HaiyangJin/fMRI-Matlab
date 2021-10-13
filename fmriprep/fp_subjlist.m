function [subjList, nSubj] = fp_subjlist(substr, bidsDir)
% [subjList, nSubj] = fp_subjlist(substr, bidsDir)
%
% Get subject codes in <bidsDir>.
%
% Inputs:
%    substr        <str> wildcard to identify subject folders. Default is
%                   'sub-*'.
%    bidsDir       <str> the BIDS directory. Default is fp_bidsdir.
%
% Outputs:
%    subjList      <cell str> list of subject codes.
%    nSubj         <int> number of subjects.
%
% Created by Haiyang Jin (2021-10-13)

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = fp_bidsdir;
end

if ~exist('substr', 'var') || isempty(substr)
    substr = 'sub-*';
elseif ~endsWith(substr, '*')
    substr = [substr '*'];
end

% get the list of subjects
subjdir = dir(fullfile(bidsDir, substr));
subjList = {subjdir.name};

nSubj = length(subjList);

end