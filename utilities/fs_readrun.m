function [runNames, nRun] = fs_readrun(runFn, sessCode, funcPath)
% [runNames, nRun] = fs_readrun(runFn, sessCode, funcPath)
%
% This function loads run file (.txt) and output the list of run numbers
%
% Inputs:
%     runFn        <string> filenames of the run file (*.txt) (with or
%                   without path).
%     sessCode     <string> session code in funcPath.
%     funcPath     <string> the full path to the functional folder.
%
% Outputs:
%     runNames     <cell of string> list of run names.
%     nRun         <integer> number of runs.
%
% Created by Haiyang Jin (08-Dec-2019)

% get the funcPath from global environment
if ~exist('funcPath', 'var') || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% if runFn is empty
if (~exist('runFn', 'var') || isempty(runFn)) && ~isempty(sessCode)
    % find names of all runs
    boldDir = dir(fullfile(funcPath, sessCode, 'bold'));
    boldDir([boldDir.isdir]~=1) = [];  % remove non-folders
    isRun = ~isnan(cellfun(@str2double, {boldDir.name}));
    runNames = {boldDir(isRun).name};
    warning('Names of all runs are used by default.');
else
    % if path is included in runFn
    path = fileparts(runFn);
    
    if isempty(path)
        % add path to runFn if sessCode is not empty
        if ~exist('sessCode', 'var') || isempty(sessCode)
            error('''sessCode'' is missing.');
        else
            runFile = fullfile(funcPath, sessCode, 'bold', runFn);
        end
    else
        runFile = runFn;
    end
    
    % read the run file
    runNames = fs_readtext(runFile);
end

% remove empty cells
runNames(cellfun(@isempty, runNames)) = [];

% number of runs
nRun = numel(runNames);

end