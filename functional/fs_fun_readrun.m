function [runNames, nRun] = fs_fun_readrun(run_fn, projStr, subjCode_bold)
% This function loads run file (.txt) and output the list of run numbers
% 
% Created by Haiyang Jin (08/12/2019)
%
% Inputs:
%    projStr     project information (obtained from fs_fun_projectinfo)
%    fn_run      filenames of the run file (*.txt) (without path)
%    subjCode    subjCode in $SUBJECTS_DIR
% Outputs:
%    runNames    a vector of run names
%    nRun        number of runs

path = fileparts(run_fn);

if isempty(path)
    if isempty(projStr) || isempty(subjCode_bold)
        error('Not enough inputs for fs_fun_readrun');
    else
        run_file = fullfile(projStr.fMRI, subjCode_bold, 'bold', run_fn);
    end
else
    run_file = run_fn;
end

% read txt files
runList = importdata(run_file); 

% covnert to a cell of char
runNames = arrayfun(@(x) sprintf('%03d', x), runList, 'UniformOutput', false);

% number of runs
nRun = numel(runList);

end