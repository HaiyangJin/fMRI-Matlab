function runList = fs_runlist(sessCode, funcPath)
% runList = fs_runlist(sessCode, funcPath)
% 
% This function reads the bold path and output the list of all run folder
% names [numeric strings].
%
% Inputs:
%     sessCode         <string> session code in funcPath or the full path 
%                       to the bold folder.
%     funcPath         <string> the full path to the functional folder.
%
% Output:
%     runList          <cell of string> a cell of folder names of all runs.
%
% Created by Haiyang Jin (7-Apr-2020)

% use the funcPath saved in global environment if needed
if nargin < 2 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

% the bold path
if ~isempty(fileparts(sessCode)) && endsWith(sessCode, 'bold')
    boldPath = sessCode;
else
    boldPath = fullfile(funcPath, sessCode, 'bold');
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

end