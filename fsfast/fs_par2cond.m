function conditions = fs_par2cond(sessList, runInfo, parFn, funcPath)
% conditions = fs_par2cond(sessList, [runList='', parFn='', funcPath])
%
% This function tries to output the unique condition names (and their
% orders) based on all the available par (paradigm) files. 
%
% Inputs:
%    sessList         <str> or <cell str> session code in $FUNCTIONALS_DIR.
%    runInfo          <str> the filename of the run file (e.g.,
%                      run_loc.txt) [Default is '' and then names of
%                      all run folders will be used.]
%                 OR  <cell STR> a list of all the run names. (e.g.,
%                      {'001', '002', '003'....}.
%    parFn            <str> the filename of the par file. It is empty by
%                      default and will try to find the par file for that run.
%    funcPath         <str> the path to the session folder,
%                      $FUNCTIONALS_DIR by default.
%
% Output:
%    conditions       <cell str> names of conditions with the same order
%                      in the par (paradigm) files.
%
% Created by Haiyang Jin (16-Apr-2020)

if ischar(sessList); sessList = {sessList}; end

if ~exist('runList', 'var') || isempty(runInfo)
    runInfo = '';
end

if ~exist('parFn', 'var') || isempty(parFn)
    parFn = '';
end

if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% create full path to the par files
if ischar(runInfo)
    % when runList is a run file name
    runNames = cellfun(@(x) fs_readrun(runInfo, x, funcPath), sessList, 'uni', false);
    % parFiles for each session
    parCells = cellfun(@(x, y) fullfile(funcPath, x, 'bold', y, parFn), ...
        sessList, runNames, 'uni', false);
    parFiles = vertcat(parCells{:});
    
elseif iscellstr(runInfo)
    % when runList is a cell of run names
    % create all possible combinations between sessList and runList
    [tempSess, tempRun] = ndgrid(sessList, runInfo);
    % all the par files
    parFiles = fullfile(funcPath, tempSess(:), 'bold', tempRun(:), parFn);
end

% read the parfiles
[parTCell, numCell] = cellfun(@fm_readpar, parFiles, 'uni', false);

if ~isequal(numCell{:})
    warning('The number of conditions are not consistent for these par files.');
end

% number(s) of conditions
nCon = unique([numCell{:}]);

condTable = unique(vertcat(parTCell{:}), 'rows');

if any(size(condTable, 1) > nCon)
    warning('There are conditions missing in some of the par files.');
end

% save the unique label names
conditions = condTable.Label;

% display the condition names (with order)
fprintf('\nThe condination names are:\n');
disp(conditions);
fprintf('Please make sure they are in the same order as that in the par file.\n');

end