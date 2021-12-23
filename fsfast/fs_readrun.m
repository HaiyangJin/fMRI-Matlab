function [runNames, nRun] = fs_readrun(runFn, sessCode)
% [runNames, nRun] = fs_readrun(runFn, sessCode)
%
% This function loads run file (.txt) and output the list of run numbers
%
% Inputs:
%     runFn        <str> filenames of the run file (*.txt) (with or
%                   without path).
%     sessCode     <str> session code in $FUNCTIONALS_DIR.
%
% Outputs:
%     runNames     <cell str> list of run names.
%     nRun         <int> number of runs.
%
% Created by Haiyang Jin (08-Dec-2019)

funcDir = getenv('FUNCTIONALS_DIR');

% if runFn is empty
if (~exist('runFn', 'var') || isempty(runFn)) && ~isempty(sessCode)
    % find names of all runs
    boldDir = dir(fullfile(funcDir, sessCode, 'bold'));
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
            runFile = fullfile(funcDir, sessCode, 'bold', runFn);
        end
    else
        runFile = runFn;
    end
    
    % read the run file
    runNames = fm_readtext(runFile);
end

% remove empty cells
runNames(cellfun(@isempty, runNames)) = [];

% number of runs
nRun = numel(runNames);

end