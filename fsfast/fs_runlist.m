function [runList, nRun] = fs_runlist(sessCode, runInfo)
% [runList, nRun] = fs_runlist(sessCode, runInfo)
%
% This function reads the bold path and output the list of all run folder
% names [numeric strings].
%
% Inputs:
%     sessCode         <str> session code in $FUNCTIONALS_DIR or the full
%                       path to the bold folder.
%     runInfo          <str> the filename of the run file (e.g.,
%                       run_loc.txt.) [Default is '' and then names of all
%                       run folders will be used.]
%                  OR  <str> analysis name. Run list will be read from the
%                       information in 'analysis.info'.
%                  OR  <str cell> a list of all the run names. (e.g.,
%                       {'001', '002', '003'....}.
%
% Output:
%     runList          <cell str> a cell of folder names of all runs.
%
% Created by Haiyang Jin (7-Apr-2020)

if ~exist('runInfo', 'var') || isempty(runInfo)
    warning('All available runs will be used.')
elseif ischar(runInfo)

    anaInfo = fs_readanainfo(runInfo, sessCode);

    % read analysis information
    if ~isempty(anaInfo)
        runInfo = anaInfo.runlistfile;
    end

    % runInfo will be used as the filename of run file
    [runList, nRun] = fs_readrun(runInfo, sessCode);
    return;

elseif iscell(runInfo)
    % runInfo will be runList
    runList = runInfo;
    nRun = numel(runList);
    return;
end

%% Identify all folders with numeric names
% the bold path
if ~isempty(fileparts(sessCode)) && endsWith(sessCode, 'bold')
    boldPath = sessCode;
else
    boldPath = fullfile(getenv('FUNCTIONALS_DIR'), sessCode, 'bold');
end

% list of all the files
allfiles = dir(boldPath);

% only keep folders
folders = allfiles;
folders(~[folders.isdir]) = [];

% the names of all folders
folderNames = {folders.name}';

% which is the run folder names (numeric strings)
isRun = ~isnan(cellfun(@str2double, folderNames));

% save the run list
runList = folderNames(isRun);
nRun = numel(runList);

end