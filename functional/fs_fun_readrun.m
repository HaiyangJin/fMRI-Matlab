function [runNames, nRun] = fs_fun_readrun(runFn, project, sessCode)
% This function loads run file (.txt) and output the list of run numbers
%
% Inputs:
%    runFn      filenames of the run file (*.txt) (with or without path)
%    project    project information (obtained from fs_fun_projectinfo)
%    sessCode    session code for functional data (functional subject code)
% Outputs:
%    runNames    a vector of run names
%    nRun        number of runs
%
% Created by Haiyang Jin (08-Dec-2019)

path = fileparts(runFn);

if isempty(path)
    if isempty(project) || isempty(sessCode)
        error('Not enough inputs for fs_fun_readrun.');
    else
        runFile = fullfile(project.funcPath, sessCode, 'bold', runFn);
    end
else
    runFile = runFn;
end

% return if the file is not available
if ~exist(runFile, 'file')
    runNames = {''};
    nRun = 0;
    [path, fn, ext] = fileparts(runFile);
    warning('Cannot find %s at %s.', [fn, ext], path); 
    return;
end

% read txt files
runList = importdata(runFile); 

% covnert to a cell of char
runNames = arrayfun(@(x) sprintf('%03d', x), runList, 'UniformOutput', false);

% number of runs
nRun = numel(runList);

end