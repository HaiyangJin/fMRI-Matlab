function bidsDir = bids_dir(bidsDir)
% bidsDir = bids_dir(bidsDir)
%
% Set bidsDir as a global environment "BIDS_DIR". bidsDir's sub-directory
% should be the BIDS folder, which saves 'sourcedata', 'derivatives',
% 'sub-x', etc (or some of them).
%
% Input:
%    bidsDir      <string> full path to the BIDS direcotry.
%
% Output:
%    bidsDir      <string> same as the input.
%    subjList     <cell str> list of subject codes.
%
% Created by Haiyang Jin (2021-10-12)

if nargin < 1 || isempty(bidsDir)
    if ~isempty(getenv("BIDS_DIR"))
        bidsDir = getenv("BIDS_DIR");
        return;
    end
    error('Please input the BIDS directory.')
end

% make sure the bidsDir exists
assert(logical(exist(bidsDir, 'dir')), 'Cannot find the directory: \n%s...', bidsDir);
setenv("BIDS_DIR", bidsDir);

end