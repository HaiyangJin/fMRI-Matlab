function fscmd = fs_bids_preproc(subjCode, varargin)
% fscmd = fs_bids_preproc(subjCode, varargin)
% 
% Create the FreeSurfer directory structure for FS-FAST from BIDS. 
% 
% Inputs:
%    subjCode     <str> bids subject code in bidsDir.
%
% Varargin:
%    .runcmd       <boo> whether run the preproc-sess commands. 1 [default]:
%                   run the command; 0: will not run but only ouput the
%                   command.
%    .smooth       <int> smoothness (default 0).
%    .template     <str> template used for projecting functional data
%                   ('self' [default] or 'fsaverage').
%    .extracmd     <str> extra command strings used for preproc-sess.
%                   default ''.
%    .combinesess  <boo> whether combine the runs from multiple runs to one
%                   session folder in FreeSurfer (FS-FAST). Default is 1.
%    .fssesscode   <str> session code in $FUNCTIONALS_DIR. It is the same as
%                   subjCode (in bidsDir) by default.
%    .fssubjcode   <str> the corresponding FreeSurfer subject code, which
%                   will be saved as subjectname in the session folder.
%    .bidsdir      <str> the BIDS directory. Default is bids_dir().
%    .strudir      <str> $SUBJECTS_DIR in FreeSurfer. Default is 
%                   <bidsDir>/derivatives/functionals.
%
% Output:
%    fscmd         <str> FreeSurfer commands.
%
% Created by Haiyang Jin (2022-02-06)

backupDir = pwd;

defaultOpts = struct( ...
    'runcmd', [], ... % use defualt in fs_preproc: 1
    'smooth', [], ... % use defualt in fs_preproc: 0
    'template', [], ... % use defualt in fs_preproc: 'self'
    'extracmd', '', ... % use defualt in fs_preproc: ''
    'combinesess', 1, ...
    'fssesscode', subjCode, ...
    'fssubjcode', subjCode, ...
    'bidsdir', bids_dir(), ...
    'funcdir', '');
opts = fm_mergestruct(defaultOpts, varargin{:});

% make sure subjCode is in <bids_dir>/
bsubjDir = fullfile(opts.bidsdir, subjCode);
assert(exist(bsubjDir, 'dir'), ['Cannot find the subject (%s) in the bids ' ...
    'folder (%s).'], subjCode, opts.bidsdir);

% make the functionals_dir
if isempty(opts.funcdir)
    opts.funcdir = fullfile(opts.bidsdir, 'derivatives', 'functionals');
end
fm_mkdir(opts.funcdir);
fs_funcdir(opts.funcdir);
cd(opts.funcdir);

%% Sessions in BIDS
% dir session folders
sessdir = dir(fullfile(bsubjDir, 'ses-*'));

fssessList = {opts.fssesscode};
if isempty(sessdir)
    % if there is only one session
    bfuncdir = {dir(fullfile(bsubjDir, 'func', '*bold.nii.gz'))};

else
    % if there are multiple sessions
    sessList = {sessdir.name};

    % all func files in all sessions
    bfuncdir = cellfun(@(x) dir(fullfile(bsubjDir, x, 'func', ...
        sprintf('%s_%s*bold.nii.gz', subjCode, x))), sessList, 'uni', false);
    bfuncdir = bfuncdir(:);

    if opts.combinesess
        % if save multiple BIDS sessions as one session in FS-FAST
        bfuncdir = {vertcat(bfuncdir{:})};
    else
        % if save multiple BIDS sessions as multiple in FS-FAST
        fssessList = cellfun(@(x) sprintf('%s_%s', ...
            opts.fssesscode, x), sessList, 'uni', false);
    end
end

assert(~isempty(bfuncdir), 'Cannot find any functional data.')

%% Conduct analysis for each FS-FAST session separately
fscmdc = cell(size(bfuncdir, 1), 1);
for iSess = 1:size(bfuncdir, 1)

    thisSess = fssessList{iSess};

    % make the FS-FAST directory for one session
    mk_sess(thisSess, bfuncdir{iSess}, opts);

    % perfrm preproc-sess
    fscmdc{iSess, 1} = fs_preproc(thisSess, opts.smooth, opts.template, opts.extracmd, opts.runcmd);
end
fscmd = vertcat(fscmdc{:});

cd(backupDir);

end

function mk_sess(thissess, bfuncdir, opts)
% This function make the directory for FS-FAST.
%
% thesess     <str> the session code in $FUNCTIONALS_DIR.
% bfuncdir    <struct> the func run information.

%% make the session folder (within the func folder)
fm_mkdir(fullfile(opts.funcdir, thissess));

%% create other files (within the session folder)
sessDir = fullfile(opts.funcdir, thissess);
boldDir = fullfile(sessDir, 'bold');
fm_mkdir(boldDir);

% create sessid
fm_mkfile(fullfile(sessDir, 'sessid'), thissess);
% create subjectname
fm_mkfile(fullfile(sessDir, 'subjectname'), opts.fssubjcode);

%% (Within the bold folder)
% list of run names
bfuncInfoC = cellfun(@fp_fn2info, {bfuncdir.name}, 'uni', false);
bfuncInfo = vertcat(bfuncInfoC{:});

runCodeList = arrayfun(@(x) sprintf('%03d', x), 1:size(bfuncInfo,1), 'uni', false)'; 
[bfuncInfo.runname] = deal(runCodeList{:});

% make dir for each run
fm_mkdir(fullfile(boldDir, runCodeList)); % make the folders for func in FreeSurfer

% copy func runs from bids to FreeSurfer
sources = fullfile({bfuncdir.folder}, {bfuncdir.name})';
targets = fullfile(fullfile(boldDir, runCodeList, 'f.nii.gz'));
cellfun(@copyfile, sources, targets);

% rename the files
% cellfun(@movefile, fullfile(targets, {bfuncdir.name}'), ...
%     fullfile(targets, 'f.nii.gz'));
% save the original filenames of f.nii.gz
cellfun(@fm_mkfile, fullfile(boldDir, runCodeList, 'f.bidsname'), ...
    {bfuncdir.name}', 'uni', false);

% save the run information
RunCode = runCodeList;
RunName = {bfuncdir.name}';
writetable(table(RunCode, RunName), fullfile(boldDir, 'run_info.txt'));

% make run list files for each task
tasks = unique({bfuncInfo.task});
for thisTask = tasks
    theTaskRuns = runCodeList(strcmp({bfuncInfo.task}', thisTask));
    fm_mkfile(fullfile(boldDir, [thisTask{1} '.txt']), theTaskRuns);
end

% make run list files for each task and each session
if isfield(bfuncInfo, 'ses') % only when ses information is available
    sess = unique({bfuncInfo.ses});
    for thisSes = sess
        for thisTask = tasks
            theTaskRuns = runCodeList(logical(strcmp({bfuncInfo.task}', thisTask) .* ...
                strcmp({bfuncInfo.ses}', thisSes)));
            fm_mkfile(fullfile(boldDir, sprintf('%s_ses-%s.txt', ...
                thisTask{1}, thisSes{1})), theTaskRuns);
        end
    end
end

end