function fscmd = fs_bids_recon(subjCode, varargin)
% fscmd = fs_bids_recon(subjCode, varargin)
%
% This function runs recon-all for one subject with BIDS directory
% structure. It is recommended to set bids_dir() in advance.
%
% Inputs:
%    bsubjCode     <str> bids subject code in bidsDir.
%
% Varargin:
%    .runcmd       <boo> whether run the recon-all commands. 1 [default]:
%                   run the command; 0: will not run but only ouput the
%                   command.
%    .hires        <boo> whether run recon-all with native high resolution.
%                   default is []; use the default in fs_recon().
%    .useall       <boo> whether use all T1 and T2 files if there are
%                   multiuple files available. 1 [default]: use all
%                   avaiable files; 0: only use the first file.
%    .fssubjcode   <str> subject code in $SUBJECTS_DIR. It is the same as
%                   subjCode (in bidsDir) by default.
%    .extracmd     <str> the extra commands to be used. Default is ''.
%    .bidsdir      <str> the BIDS directory. Default is bids_dir().
%    .subjdir      <str> $SUBJECTS_DIR in FreeSurfer. Default is 
%                   <bidsDir>/derivatives/subjects.
%
% Output:
%    fscmd         <str> FreeSurfer commands.
%
% % Example: only create recon-all command but not run
% fscmd = fs_bids_recon('sub-001', 0);
%
% Created by Haiyang Jin (2021-11-04)

if nargin < 1
    fprintf('Usage: fscmd = fs_bids_recon(subjCode, varargin);\n');
    return;
end

defaultOpts = struct( ...
    'runcmd', [], ...
    'hires', [], ...
    'useall', 1, ...
    'extracmd', '', ...
    'fssubjcode', subjCode, ...
    'bidsdir', bids_dir());

opts = fm_mergestruct(defaultOpts, varargin{:});

if ~isfield(opts, 'subjdir') || isempty(opts.subjdir)
    if ~isempty(getenv('SUBJECTS_DIR'))
        opts.subjdir = getenv('SUBJECTS_DIR');
    else
        opts.subjdir = fullfile(opts.bidsdir, 'derivatives', 'subjects');
    end
end
fm_mkdir(opts.subjdir);
fs_subjdir(opts.subjdir); 

subjDir = fullfile(opts.bidsdir, subjCode);
assert(exist(subjDir, 'dir'), ['Cannot find the subject (%s) in the bids ' ...
    'folder (%s).'], subjCode, opts.bidsdir);
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
if ~opts.useall
    t1list = t1list(1);
    t2list = t2list(1);
end

fprintf('Following files were used in ''recon-all'' for %s:\n%s\n', subjCode, ...
     sprintf('T1 files (%d)%s \nT2 files (%d)%s', ...
     length(t1list), sprintf('\n%s ', t1list{:}), ...
     length(t2list), sprintf('\n%s ', t2list{:})));

% create (and run) recon-all commands
fscmd = fs_recon(t1list, opts.fssubjcode, t2list, opts.hires, opts.extracmd, opts.runcmd);

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