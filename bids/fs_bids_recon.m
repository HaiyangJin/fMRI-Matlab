function fscmd = fs_bids_recon(subjCode, fsSubjCode, runcmd, useall, bidsDir)
% fscmd = fs_bids_recon(subjCode, runcmd, useall, bidsDir)
%
% This function runs recon-all for one subject with BIDS directory
% structure.
%
% Inputs:
%    subjCode      <str> subject code in bidsDir.
%    runcmd        <boo> whether run the recon-all commands. 1 [default]:
%                   run the command; 0: will not run but only ouput the
%                   command.
%    useall        <boo> whether use all T1 or T2 files if there are
%                   multiuple files available. 1 [default]: use all
%                   avaiable files; 0: only use the first file.
%    fsSubjCode    <str> subject code in $SUBJECTS_DIR. It is the same as
%                   subjCode (in bidsDir) by default.
%    bidsDir       <str> the BIDS directory. Default is bids_dir().
%
% Output:
%    fscmd         <str> FreeSurfer commands.
%
% % Example: only create recon-all command but not run
% fscmd = fs_bids_recon('subjcode', '', 0);
%
% Created by Haiyang Jin (2021-11-04)

if ~exist('runcmd', 'var')
    runcmd = [];
end

if ~exist('useall', 'var') || isempty(useall)
    useall = 1;
end

if ~exist('fsSubjCode', 'var') || isempty(fsSubjCode)
    fsSubjCode = subjCode;
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

subjDir = fullfile(bidsDir, subjCode);
% dir session folders
sessdir = dir(fullfile(subjDir, 'ses-*'));

% dir all T1 and T2 files
if isempty(sessdir)
    % if there is no session folders
    t1list = diranafile(subjCode, subjDir, 'T1w');
    t2list = diranafile(subjCode, subjDir, 'T2w');

else
    % if there is session folders
    sessList = fullfile(subjDir, {sessdir.name});

    t1cell = cellfun(@(x) diranafile(subjCode, x, 'T1w'), sessList, 'uni', false);
    t2cell = cellfun(@(x) diranafile(subjCode, x, 'T2w'), sessList, 'uni', false);

    t1list = vertcat(t1cell{:});
    t2list = vertcat(t2cell{:});
end

% whether use all avaiable files
if ~useall
    t1list = t1list(1);
    t2list = t2list(1);
end

fprintf('\n%d T1 and %d T2 files were used in ''recon-all'' for %s.\n', ...
    length(t1list), length(t2list), subjCode);

% create (and run) recon-all commands
fscmd = fs_recon(t1list, fsSubjCode, t2list, runcmd);

end

function filelist = diranafile(subjCode, folder, anastr)
% subjCode: subject codes in bidsDir;
% folder: the folder containing 'anat';
% anastr: 'T1w' or 'T2w'.

% dir the target files
thedir = dir(fullfile(folder, 'anat', ...
    sprintf('%s*%s.nii.gz', subjCode, anastr)));

if isempty(thedir)
    warning('Failed to find ''%s'' in %s.', anastr, ...
        fullfile(folder, 'anat'));
    filelist = {};
    return;
end

% absolute path to the target files
filelist = fullfile(thedir.folder, thedir.name);
if ischar(filelist)
    filelist = {filelist};
end

end