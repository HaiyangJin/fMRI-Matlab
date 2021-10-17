function bidsDir = bids_dir(bidsDir, isfped)
% bidsDir = bids_dir(bidsDir, isfped)
%
% Set bidsDir as a global environment "BIDS_DIR". bidsDir's sub-directory
% should be the BIDS folder, which saves 'sourcedata', 'derivatives',
% 'sub-x', etc (or some of them).
%
% When BIDS is already pre-processed by fmriPrep (isfped = 1),
% $SUBJECTS_DIR in FreeSurfer will be setup. You may want to set up
% FreeSurfer via fs_setup() first, otherwise $SUBJECTS_DIR will be
% overwritten by fs_setup(). 
%
% Input:
%    bidsDir      <str> full path to the BIDS direcotry.
%    isfped       <boo> whether the BIDS is already pre-processed by
%                  fmriPrep. 
%
% Output:
%    bidsDir      <str> same as the input.
%
% Created by Haiyang Jin (2021-10-12)
%
% See also:
% bids_dcm2bids; bids_subjlist; fs_subjdir

%% Set the BIDS dir
if ~exist('bidsDir', 'var') || isempty(bidsDir)
    if ~isempty(getenv("BIDS_DIR"))
        bidsDir = getenv("BIDS_DIR");
    else
        error('Please input the BIDS directory.')
    end
else
    % make sure the bidsDir exists
    assert(logical(exist(bidsDir, 'dir')), 'Cannot find the directory: \n%s...', bidsDir);
    setenv("BIDS_DIR", bidsDir);
end

%% When BIDS is already preprocessed by fmriPrep
if ~exist('isfped', 'var') || isempty(isfped)
    isfped = 0;
end

if isfped
    % set $SUBJECTS_DIR
    fsstruDir = fullfile(bidsDir, 'derivatives', 'freesurfer');
    fs_subjdir(fsstruDir, '', 1);
end

end