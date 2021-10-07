function [runlist, nRun] = hcp_runlist(subjCode, runinfo)
% [runlist, nRun] = hcp_runlist(subjCode, runinfo)
%
% This function lists all the run (or folder) names matching <runinfo>. If
% <runinfo> is char, it will be treated as wildcard.
% 
% Inputs:
%    subjCode      <string> subject code.
%    runinfo       <cell string> list of run folders.
%               or <string> string pattern (wildcard) to match run folders.
%                   '*' will list all the files.
%
% Outputs:
%    runlist       <cell str> a list of run (folder) names.
%    nRun          <int> number of runs (folders).
%
% % Example 1: list all localizer runs (assume the run name includes 'loc')
% hcp_runlist(subjCode, 'tfMRI*loc*');
%
% % Example 2: list all second level results (assume folder starts with 'level2')
% hcp_runlist(subjCode, 'level2*');
%
% % Example 3: list one specific run
% hcp_runlist(subjCode, {'tfMRI_Run01_PA'}); % it has to be cell str.
% 
% Created by Haiyang Jin (2021-10-06)

% setup
if ~exist('runinfo', 'var') || isempty(runinfo)
    warning('All available folders are identified.'); 
    runinfo = '*';
end

% get the run list
if ischar(runinfo) 
    
    runPath = fullfile(hcp_funcdir(subjCode), runinfo);
    
    % make it to wildcard if a char is not
    if exist(runPath, 'dir')
        runPath = [runPath '*'];
    end
    
    rundir = dir(runPath);
    runlist = {rundir.name};
    
elseif iscell(runinfo)
    % do nothing if it is cell
    runlist = runinfo;
end

nRun = length(runlist);

end