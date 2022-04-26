function fs_addrunfile(sessList, runFn, groups, runExtraFn)
% fs_addrunfile(sessList, runFn, groups, runExtraFn)
%
% Adds more run files if needed, e.g., separate 4 runs into two parts.
%
% Inputs:
%    sessList    <cell str> a list of sessions in $FUNCTIONALS_DIR.
%    runFn       <str> the run filename. 
%    groups      <boo mat> PxQ boolean matrix. P is the nunmber of runs in
%                 the runFn. Q is the number of run files to be created.
%                 Each column represents which of the runs will be saved as
%                 a separate one. Default is each run is saved as a
%                 separate run file.
%    runExtraFn  <str> the extra strings to be added at the end of runFn.
%                 Default is ''.
%
% Output:
%    A gorup of newly added run files.
%
% Created by Haiyang Jin (2022-03-03)

%% Deal with the inputs
if nargin < 1
    fprintf('Usage: fs_addrunfile(sessList, runFn, groups, runExtraFn);\n');
    return;
end

if ischar(sessList); sessList = {sessList}; end
nSess = numel(sessList);

expruns = fs_readrun(runFn, sessList{1});
nRuns = size(expruns,1);

% groups
if ~exist('groups', 'var') || isempty(groups)
    groups = eye(nRuns);
else
    nGroupRow = size(groups, 1);
    assert(nRuns == nGroupRow, ['The row number of ''groups'' (%d) should ' ...
        'match that of run file (%d)'], nGroupRow, nRuns);
end
groups = logical(groups);
nGroup = size(groups, 2);

if ~exist('runExtraFn', 'var') || isempty(runExtraFn)
    runExtraFn = '';
end

%% Add more run files
for iSess = 1:nSess
    % read the run file
    thisexpruns = fs_readrun(runFn, sessList{iSess});

    % get the updated run file lists and names
    runC = arrayfun(@(x) thisexpruns(groups(:,x)), 1:nGroup, 'uni', false);
    runnameC = arrayfun(@(x) sprintf('%s%s%02d.txt', erase(runFn, '.txt'), ...
        runExtraFn, x), 1:nGroup, 'uni', false);
    % create the new fun files
    cellfun(@(x,y) fm_mkfile(fullfile(getenv('FUNCTIONALS_DIR'), ...
        sessList{iSess}, 'bold', x), y), runnameC, runC, 'uni', false);

end

end