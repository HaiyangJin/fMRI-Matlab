function [runNames, nRun] = fs_readrun(fn_run)
% This function loads run file (.txt) and output the list of run numbers
% 
% Created by Haiyang Jin (08/12/2019)
%
% Inputs:
%    fn_run      filenames of the run file (*.txt)
% Outputs:
%    runNames    a vector of run names
%    nRun        number of runs

% read txt files
runList = importdata(fn_run); 

% covnert to a cell of char
runNames = arrayfun(@(x) sprintf('%03d', x), runList, 'UniformOutput', false);

% number of runs
nRun = numel(runList);

end