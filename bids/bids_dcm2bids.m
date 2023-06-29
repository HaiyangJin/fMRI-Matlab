function [d2bcmd, isnotok] = bids_dcm2bids(dcmSubj, outSubj, config, isSess, runcmd, bidsDir)
% [d2bcmd, isnotok] = bids_dcm2bids(dcmSubj, outSubj, config, isSess, runcmd, bidsDir)
%
% This function run dcm2bids for DICOM files. DICOM files should be saved
% in a folder called "sourcedata" within bidsDir.
%
% Note:
%    1. dcm2bids will not set the correct    field in fmap json
% files. Please check bids_fixfmap for details.
%    2. the 'TaskName' needs to be set for functional runs, you may want to
% use bids_fixfunc.
%
% Inputs:
%    dcmSubj       <cell str> a list of subject folders saving DICOM files.
%               OR <str> wildcard strings to match the subject folders
%                   saving DICOM files.
%    outSubj       <cell str> a list of output subject codes (e.g., {'X01',
%                   'X02', ...}). It needs to have the same length as
%                   dcmSubj. Default is {'01', '02', ...} depending on
%                   dcmSubj. It only makes sense to input cell string when
%                   <dcmSubj> is also cell str. Each string in outSubj
%                   correspond each string in outSubj.
%               OR <str> strings to be put before {'01', '02, ...}. E.g.,
%                   when outSubj is 'Test', the subjcode will be
%                   'sub-Test01', 'sub-Test02'.
%    config        <str> the config file to deal with dicoms. The default
%                   config file is <bidsDir>/code/bids_convert.json .
%    isSess        <boo> If there are multiple subdir within dcmSubj
%                   dir. Whether these dirctories are sessions (or runs).
%                   Default is 0 (i.e., runs). Note that if run folders are
%                   mistaken as session folders, each run will be saved as
%                   a separate session. No messages will be displayed for
%                   this case but you will notice it in the output. A
%                   special usage of isSess is: when isSess is not 0 and
%                   there is only one folder withi9n subdir, isSess will be
%                   used as the session code.
%    runcmd        <boo> Whether to run the commands. Default is 1.
%    bidsDir       <str> the BIDS directory. Default is bids_dir().
%
% Outputs:
%    d2bcmd        <cell str> dcm2bids commands.
%    isnotok       <vec> status of running d2bcmd.
%    BIDS saved in <bidsDir>/bids/
%
% Created by Haiyang Jin (2021-10-13)
%
% See also:
% [bids_dir;] bids_mktsv; bids_fixfmap; bids_fixfunc; bids_mkignore

if nargin < 1
    fprintf('Usage: [d2bcmd, isnotok] = bids_dcm2bids(dcmSubj, outSubj, config, isSess, runcmd, bidsDir);\n');
    return;
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

if ~exist('config', 'var') || isempty(config)
    config = fullfile(bidsDir, 'code', 'bids_convert.json');
end
% make sure the config file exist
assert(logical(exist(config, 'file')), 'Cannot find the config file:\n%s', config);

% make sure the DICOM files/folder exist
dcmDir = fullfile(bidsDir, 'sourcedata');
assert(logical(exist(dcmDir, 'dir')), 'Cannot find sourcedata/ in %s', bidsDir);

% deal with the list of subject codes for dicom files
if ischar(dcmSubj)
    if ~endsWith(dcmSubj, '*'); dcmSubj=[dcmSubj '*'];end
    dSubjdir = dir(fullfile(dcmDir, dcmSubj));
    dsubjList = {dSubjdir.name};
elseif iscell(dcmSubj)
    dsubjList = dcmSubj;
end

% deal with the list of subject codes for output
if ~exist('outSubj', 'var') || isempty(outSubj)
    outSubj = '';
end
if ischar(outSubj)
    outSubj = arrayfun(@(x) sprintf([outSubj '%02d'], x), 1:length(dsubjList), 'uni', false);
else
    assert(length(dsubjList) == length(outSubj), ...
        'The length of "dcmSubj" (%d) and "outSubj" (%d) is not the same.', ...
        length(dsubjList), length(outSubj));
end

if ~exist('isSess', 'var') || isempty(isSess)
    isSess = 0;
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

%% Make and run dcm2bids
cmdCell = cell(length(dsubjList),1);

for iSubj = 1:length(dsubjList)

    if ~startsWith(dsubjList{iSubj}, filesep)
        dsubjDir = fullfile(dcmDir, dsubjList{iSubj});
    else
        dsubjDir = dsubjList{iSubj};
    end

    dcmdir = dir(dsubjDir);
    dcmdir(ismember({dcmdir.name}, {'.', '..'}))= [];
    dcmSess = dcmdir([dcmdir.isdir]);

    if isempty(dcmSess)
        % if no subdir is found in dcmDir, there is only 1 session
        cmd = {sprintf(['dcm2bids '...
            '-d %s -o %s -p %s -c %s --forceDcm2niix --clobber'], ...
            fm_2cmdpath(dsubjDir), fm_2cmdpath(bidsDir), outSubj{iSubj}, config)};

    elseif ~isSess
        % if the subdir in dsubjDir are runs (instead of sessions)
        runfolders = fullfile(dsubjDir, {dcmSess.name});
        cmd = {sprintf(['dcm2bids '...
            '-d %s -o %s -p %s -c %s --forceDcm2niix --clobber'], ...
            sprintf('%s ', runfolders{:}),...
            fm_2cmdpath(bidsDir), outSubj{iSubj}, config)};

    elseif isSess

        dcmid = 1:length(dcmSess);
        sessid = dcmid;
        if length(dcmid)==1; sessid = isSess; end

        % if the subdir in dsubjDir are sessions
        cmd = arrayfun(@(x,y) sprintf(['dcm2bids '...
            '-d %s -o %s -p %s -s %d -c %s --forceDcm2niix --clobber'],...
            fm_2cmdpath(fullfile(dsubjDir, dcmSess(x).name)), fm_2cmdpath(bidsDir), ...
            outSubj{iSubj}, y, config), ...
            dcmid, sessid, 'uni', false)';
    end

    cmdCell{iSubj, 1} = cmd;
end

d2bcmd = vertcat(cmdCell{:});
% run cmd
[~, isnotok] = fm_runcmd(d2bcmd, runcmd);

end