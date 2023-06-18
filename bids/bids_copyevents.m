function copypair = bids_copyevents(subjCode, eventwd, runwd, ses, bidsDir)
% copypair = bids_copyevents(subjCode, eventwd, runwd, ses, bidsDir)
%
% Inputs:
%    subjCode        <str> subject code in bids_subjlist().
%    eventwd         <cell str> wildcards to be used to identify the event
%                     files to be copied.
%    runwd           <cell str> wildcards to be used to identify the
%                     functional runs (BOLD), whose names will be used as
%                     the new names for the event files.
%    ses             <str> the session name. Default is '', i.e., no
%                     session informaiton/folder is available.
%    bidsDir         <str> the BIDS directory. Default is bids_dir().
%
% Output
%    copypair        <cell str> the pairs of the source and target file
%                     names. The first column is the source files and the
%                     second column is the target files.
%
% Created by Haiyang Jin (2022-April-8)

if nargin < 1
    fprintf('Usage: copypair = bids_copyevents(subjCode, eventwd, runwd, ses, bidsDir);\n');
    return;
end

if ~exist('bidsDir', 'var') || isempty(bidsDir)
    bidsDir = bids_dir();
end

assert(ismember(subjCode, bids_subjlist('', bidsDir)), ...
    'Cannot find subjCode (%s) in the bids directory.', subjCode);

if ~exist('eventwd', 'var') || isempty(eventwd)
    eventwd = sprintf('%s*', subjCode);
end
if ~exist('runwd', 'var') || isempty(runwd)
    runwd = '*_bold.nii.gz';
end
% make sure eventwd and runwd have
if ischar(eventwd); eventwd = {eventwd}; end
if ischar(runwd); runwd = {runwd}; end
nwd = length(eventwd);
assert(nwd == length(runwd), ['eventwd (%d) and runwd (%d) should have the' ...
    ' same length.'], nwd, length(runwd));

if ~exist('ses', 'var') || isempty(ses)
    ses = '';
elseif isnumeric(ses)
    ses = num2str(ses);
end
if ~isempty(ses) && ~startsWith(ses, 'ses-')
    ses = sprintf('ses-%s', ses);
end

%% Find and copy files
copycells = cell(nwd, 1);
copycellt = cell(nwd, 1);

for iwd = 1:nwd

    % the source filenames
    sourcedir = dir(eventwd{iwd});
    sources = fullfile({sourcedir.folder}, {sourcedir.name});

    assert(~isempty(sources), 'Cannot find any eligible source file.')

    % the target filenames
    bolddir = dir(fullfile(bidsDir, subjCode, ses, 'func', runwd{iwd}));
    targetevents = cellfun(@(x) strrep(x, '_bold.nii.gz', '_events.tsv'), ...
        {bolddir.name}, 'uni', false);
    targets = fullfile({bolddir.folder}, targetevents);

    assert(~isempty(targets), 'Cannot find any potential target file.')

    % copy event files
    cellfun(@(x,y) copyfile(x,y), sources, targets, 'uni', false);

    copycells{iwd, 1} = {sourcedir.name}';
    copycellt{iwd, 1} = targetevents';
end

copypair = horzcat(vertcat(copycells{:}), vertcat(copycellt{:}));

end