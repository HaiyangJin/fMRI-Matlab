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
%    .tsv2par      <boo> whether to convert tsv from bids to par files in
%                   FreeSurfer. Default is 1.
%    .combinesess  <boo> whether combine the runs from multiple runs to one
%                   session folder in FreeSurfer (FS-FAST). Default is 0.
%    .fssesscode   <str> session code in $FUNCTIONALS_DIR. It is the same as
%                   subjCode (in bidsDir) by default.
%    .fssubjcode   <str> the corresponding FreeSurfer subject code, which
%                   will be saved as subjectname in the session folder.
%    .bidsdir      <str> the BIDS directory. Default is bids_dir(). For
%                   example, to extract data from fmriprep output, set
%                   `.bidsdir` to 'path/to/derivatives/fmriprep'.
%    .funcwc       <str> wildcard to identify functional data files to be
%                   copied to `.funcdir` folder. Default to
%                   '*.bold.nii.gz'. It should not include subject or
%                   session information (which will be added automatically).
%    .funcdir      <str> $FUNCTIONALS_DIR in FreeSurfer. Default is 
%                   <bidsDir>/derivatives/functionals.
%
% Output:
%    fscmd         <str> FreeSurfer commands.
%
% Created by Haiyang Jin (2022-02-06)

if nargin < 1
    fprintf('Usage: fscmd = fs_bids_preproc(subjCode, varargin);\n');
    return;
end

backupDir = pwd;

defaultOpts = struct( ...
    'runcmd', 1, ... % use defualt in fs_preproc: 1
    'smooth', [], ... % use defualt in fs_preproc: 0
    'template', [], ... % use defualt in fs_preproc: 'self'
    'extracmd', '', ... % use defualt in fs_preproc: ''
    'tsv2par', 1, ... 
    'combinesess', 0, ...
    'fssesscode', subjCode, ...
    'fssubjcode', subjCode, ...
    'bidsdir', bids_dir(), ...
    'funcwc', '*bold.nii.gz', ... it should not include subject or session information
    'funcdir', '');
opts = fm_mergestruct(defaultOpts, varargin{:});

% make sure subjCode is in <bids_dir>/
bsubjDir = fullfile(opts.bidsdir, subjCode);
assert(exist(bsubjDir, 'dir'), ['Cannot find the subject (%s) in the bids ' ...
    'folder (%s).'], subjCode, opts.bidsdir);

% make the functionals_dir
if isempty(opts.funcdir)
    if isempty(getenv('FUNCTIONALS_DIR'))
        opts.funcdir = fullfile(opts.bidsdir, 'derivatives', 'functionals');
    else
        opts.funcdir = getenv('FUNCTIONALS_DIR');
    end
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
    bfuncdir = {dir(fullfile(bsubjDir, 'func', opts.funcwc))};

else
    % if there are multiple sessions
    sessList = {sessdir.name};

    % all func files in all sessions
    bfuncdir = cellfun(@(x) dir(fullfile(bsubjDir, x, 'func', ...
        sprintf('%s_%s%s', subjCode, x, opts.funcwc))), sessList, 'uni', false);
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

assert(any(cellfun(@(x) ~isempty(x), bfuncdir)), ...
    'Cannot find any matched functional data with "(%s)".', opts.funcwc)

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
% stupid way to make bfuncInfoC have the same fieldnames
bfuncInfo = fm_vmergestruct(bfuncInfoC{:});

% get the json filenames
jsonfns = cellfun(@(x) strrep(x, '.nii.gz', '.json'), {bfuncdir.name}, 'uni', false);
[bfuncdir.jsname] = deal(jsonfns{:});
% get the run series number
vals = cellfun(@(x) jsondecode(fileread(x)), ...
    fullfile({bfuncdir.folder}, {bfuncdir.jsname}), 'uni', false);
runCodeList = vertcat(vals{:});
if isfield(runCodeList, 'SeriesNumber')
    [bfuncInfo.sn] = runCodeList.SeriesNumber;
else
    warning('Custom Series Number is used as the run folder names...');
    tmpSeriesNumber = num2cell(1:length(bfuncInfo));
    [bfuncInfo.sn] = tmpSeriesNumber{:};
end

% add dummy ses if there are no session info
if ~isfield(bfuncInfo, 'ses') || ~opts.combinesess
    emptyses = repmat({'0'}, length(bfuncInfo), 1);
    [bfuncInfo.ses] = emptyses{:};
end

runCodeList = arrayfun(@(x) sprintf('%s%02d', bfuncInfo(x).ses, bfuncInfo(x).sn), ...
    1:size(bfuncInfo,1), 'uni', false)'; 
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
    sources, 'uni', false);

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
if opts.combinesess     % only when the sessions are combined
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

% convert events.tsv to *.par files if needed
if opts.tsv2par
    % source tsv file lists
    eventlist = cellfun(@(x) strrep(x, '_bold.nii.gz', '_events.tsv'), ...
        sources, 'uni', false);
    % check if all source files exist
    allexist = all(cellfun(@(x) logical(exist(x, 'file')), eventlist));

    if allexist
        % target par file lists
        parlist = cellfun(@(x,y) strrep(x, 'f.nii.gz', sprintf('%s.par',y)), ...
            targets, {bfuncInfo.task}', 'uni', false);
        
        cellfun(@fm_event2par, eventlist, parlist);
    end
end

end