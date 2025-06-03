function [d2bcmd, isnotok] = bids_dcm2bids(dcmSubj, outSubj, varargin)
% [d2bcmd, isnotok] = bids_dcm2bids(dcmSubj, outSubj, varargin)
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
%
% Varargin:
%    .config       <str> the config file to deal with dicoms. The default
%                   config file is <bidsDir>/code/bids_convert.json .
%    .isSess       <boo> If there are multiple subdir within dcmSubj
%                   dir. Whether these dirctories are sessions (or runs).
%                   Default is 0 (i.e., runs). Note that if run folders are
%                   mistaken as session folders, each run will be saved as
%                   a separate session. No messages will be displayed for
%                   this case but you will notice it in the output. A
%                   special usage of isSess is: when isSess is not 0 and
%                   there is only one folder withi9n subdir, isSess will be
%                   used as the session code.
%    .docker       <boo> the docker version to be used, default to '3.2.0'
%    .runcmd       <boo> Whether to run the commands. Default is 1.
%    .bidsDir      <str> the BIDS directory. Default is bids_dir().
%    .relapath     <boo> whether to use relative path for bidsDir in
%                   d2bcmd. Default to 0. 
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
    fprintf('Usage: [d2bcmd, isnotok] = bids_dcm2bids(dcmSubj, outSubj, varargin);\n');
    return;
end

defaultOpts = struct(...
    'config', [], ...
    'issess', 0, ...
    'docker', '3.2.0', ...
    'runcmd', 1, ...
    'bidsdir', bids_dir(), ...
    'relapath', 0 ...
    );
opts = fm_mergestruct(defaultOpts, varargin);

isSess = opts.issess;
runcmd = opts.runcmd;
bidsDir = opts.bidsdir;
docker = opts.docker;
if isempty(opts.config)
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
        if isempty(docker)
            % if no subdir is found in dcmDir, there is only 1 session
            cmd = {sprintf(['dcm2bids '...
                '-d %s -o %s -p %s -c %s --force_dcm2bids --clobber'], ...
                fm_2cmdpath(dsubjDir), fm_2cmdpath(bidsDir), outSubj{iSubj}, config)};
        else
            cmd = {sprintf(['docker run --rm -it ' ...
                '-v %s:/dicoms:ro -v %s:/bids -v %s:/config.json:ro ' ...
                'unfmontreal/dcm2bids:%s --force_dcm2bids --clobber ' ...
                '-d /dicoms -o /bids -p %s -c /config.json'], ...
                fm_2cmdpath(dsubjDir), fm_2cmdpath(bidsDir), config, ...
                docker, outSubj{iSubj})};
        end

    elseif ~isSess
        % if the subdir in dsubjDir are runs (instead of sessions)
        runfolders = fullfile(dsubjDir, {dcmSess.name});

        if isempty(docker)
            cmd = {sprintf(['dcm2bids '...
                '-d %s -o %s -p %s -c %s --force_dcm2bids --clobber'], ...
                sprintf('%s ', runfolders{:}),...
                fm_2cmdpath(bidsDir), outSubj{iSubj}, config)};
        else
            cmd = {sprintf(['docker run --rm -it ' ...
                '-v %s:/dicoms:ro -v %s:/bids -v %s:/config.json:ro ' ...
                'unfmontreal/dcm2bids:%s --force_dcm2bids --clobber ' ...
                '-d /dicoms -o /bids -p %s -c /config.json'], ...
                fm_2cmdpath(dsubjDir), fm_2cmdpath(bidsDir), config, ...
                docker, outSubj{iSubj})};
        end

    elseif isSess

        dcmid = 1:length(dcmSess);
        sessid = dcmid;
        if isscalar(dcmid); sessid = isSess; end

        % if the subdir in dsubjDir are sessions
        if isempty(docker)
            cmd = arrayfun(@(x,y) sprintf(['dcm2bids '...
                '-d %s -o %s -p %s -s %d -c %s --force_dcm2bids --clobber'],...
                fm_2cmdpath(fullfile(dsubjDir, dcmSess(x).name)), fm_2cmdpath(bidsDir), ...
                outSubj{iSubj}, y, config), ...
                dcmid, sessid, 'uni', false)';
        else
            cmd = arrayfun(@(x,y) sprintf(['docker run --rm -it ' ...
                '-v %s:/dicoms:ro -v %s:/bids -v %s:/config.json:ro ' ...
                'unfmontreal/dcm2bids:%s --force_dcm2bids --clobber ' ...
                '-d /dicoms -o /bids -p %s -s %d -c /config.json'], ...
                fm_2cmdpath(fullfile(dsubjDir, dcmSess(x).name)), ...
                fm_2cmdpath(bidsDir), config, ...
                docker, outSubj{iSubj}, y), ...
                dcmid, sessid, 'uni', false)';
        end
    end

    cmdCell{iSubj, 1} = cmd;
end

d2bcmd = vertcat(cmdCell{:});

% use relative path if needed
if opts.relapath
    d2bcmd = cellfun(@(x) strrep(x, fm_2cmdpath(bidsDir), '.'), ...
        d2bcmd, 'uni', false);
end

if ispc
    d2bcmd = fm_2wslcmd(d2bcmd);
end

% run cmd
[~, isnotok] = fm_runcmd(d2bcmd, runcmd);

end