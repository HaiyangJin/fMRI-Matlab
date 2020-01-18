function [runNames, nRun] = fs_fun_readrun(runFn, projStr, subjCodeBold)
% This function loads run file (.txt) and output the list of run numbers
% 
% Created by Haiyang Jin (08/12/2019)
%
% Inputs:
%    projStr     project information (obtained from fs_fun_projectinfo)
%    runFn      filenames of the run file (*.txt) (without path)
%    subjCode    subjCode in $SUBJECTS_DIR
% Outputs:
%    runNames    a vector of run names
%    nRun        number of runs

path = fileparts(runFn);

if isempty(path)
    if isempty(projStr) || isempty(subjCodeBold)
        error('Not enough inputs for fs_fun_readrun');
    else
        runFile = fullfile(projStr.funcPath, subjCodeBold, 'bold', runFn);
    end
else
    runFile = runFn;
end

% read txt files
runList = importdata(runFile); 

% covnert to a cell of char
runNames = arrayfun(@(x) sprintf('%03d', x), runList, 'UniformOutput', false);

% number of runs
nRun = numel(runList);

end