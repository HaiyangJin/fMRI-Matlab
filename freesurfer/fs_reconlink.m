function [cmdlist, isnotok] = fs_reconlink(subjList, trglist, rmtrg, runcmd, struDir)
% [cmdlist, isnotok] = fs_reconlink(subjList, trglist, rmtrg, runcmd, struDir)
%
% Since FreeSurfer 7.4.1 (or nearby), it use soft link to build connections
% between old and new file names (e.g., ?h.pial -> ?h.pial.T2). However,
% this link information may be lost after copying. This function re-build
% the links.
%
% Inputs:
%    subjList       <cell str> a list of subjCode.
%    trglist        <cell str> a list of link files to be created.
%    rmtrg          <boo> whether to remove the target (link) if it exists.
%                    Default to 1.
%    runcmd         <boo> whether to run the cmd. Default to 1.
%    struDir        <str> $SUBJECTS_DIR.
%
% Output:
%    re-build link files in surf/.
%
% Created by Haiyang Jin (2025-July-16)

if nargin < 1
    fprintf('Usage: [cmdlist, isnotok] = fs_reconlink(subjList, trglist, rmtrg, runcmd, struDir);\n');
    return;
end

if ischar(subjList)
    subjList = {subjList};
end

if ~exist('struDir', 'var') || isempty(struDir)
    struDir = getenv('SUBJECTS_DIR');
end

if ~exist('rmtrg', 'var') || isempty(rmtrg)
    rmtrg = 1;
end

if ~exist('runcmd', 'var') || isempty(runcmd)
    runcmd = 1;
end

lists = {'lh.fsaverage.sphere.reg', 'lh.sphere.reg';
    'lh.pial', 'lh.pial.T2';
    'lh.white.H', 'lh.white.preaparc.H';
    'lh.white.K', 'lh.white.preaparc.K';
    'rh.fsaverage.sphere.reg', 'rh.sphere.reg';
    'rh.pial', 'rh.pial.T2';
    'rh.white.H', 'rh.white.preaparc.H';
    'rh.white.K', 'rh.white.preaparc.K'};

if ~exist('trglist', 'var') || isempty(trglist)
    trglist = lists(:,1);
elseif ischar(trglist)
    trglist = {trglist};
end

% find the corresponding src
[tf, loc] = ismember(trglist, lists(:,1));
srclist = repmat({''}, size(trglist)); % Default empty
srclist(tf) = lists(loc(tf), 2);

% remove ''
toKeep = ~strcmp(srclist, '');
trglist = trglist(toKeep);
srclist = srclist(toKeep);

% add path
srclists = fm_fullfile(struDir, subjList, 'surf', srclist);
trglists = fm_fullfile(struDir, subjList, 'surf', trglist);

% make the command
cmdlist = cellfun(@(x,y) sprintf('ln -s %s %s', x, y), ...
    srclists, trglists, 'uni', false);

%% Run the command
% remove the target link (if exists)
if rmtrg
    cmdtrg = cellfun(@(x) sprintf('[ -f "%s" ] && [ ! -s "%s" ] && rm "%s"', ...
        x, x, x), trglists, 'uni', false);
    % remove target link
    fm_runcmd(cmdtrg, runcmd);
end

% make the link
[~, isnotok] = fm_runcmd(cmdlist, runcmd);

end

