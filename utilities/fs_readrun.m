function [runNames, nRun] = fs_readrun(runFn, sessCode, funcPath)
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

path = fileparts(runFn);

if isempty(path)
    
    % get the funcPath from global environment
    if nargin < 3 || isempty(funcPath)
        funcPath = getenv('FUNCTIONALS_DIR');
    end
    
    if nargin < 2 || isempty(sessCode)
        error('Not enough inputs for fs_readrun.');
    else
        runFile = fullfile(funcPath, sessCode, 'bold', runFn);
    end
else
    runFile = runFn;
end

% read the run file
runNames = fs_readtext(runFile);

% number of runs
nRun = numel(runNames);

end