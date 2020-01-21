function fs_bbregister(project, sessCode, runFolder)
% This function does the automatic registration between the tempalte.nii.gz
% and the structure. For more information, please check
% https://surfer.nmr.mgh.harvard.edu/fswiki/MultiModalTutorialV6.0/MultiModalRegistration.
%
% Inputs:
%     project           project information (created by fs_fun_projectinfo)
%     sessCode          session code in functional folder (it could be a
%                       cell array)
%     runFolder         the run folder names
%
% Output:
%     files named 'register.lta' and 'register.dat'
%
% Created by Haiyang Jin (20-Jan-2020)

if nargin < 2 || isempty(sessCode)
    sessCode = project.sessList;  % all sessions
elseif ischar(sessCode)
    sessCode = {sessCode};
end

% path to functional folder
funcPath = project.funcPath;

nSess = numel(sessCode);
for iSess = 1:nSess
    
    thisSess = sessCode{iSess};
    thisSubjCode = fs_subjcode(thisSess, funcPath);
    theBoldPath = fullfile(funcPath, thisSess, 'bold');
    
    % get the run list
    if nargin < 3 || isempty(runFolder)  % all runs
        % get the list of run folders (with numbers only)
        locRunList = fs_fun_readrun('run_loc.txt', project, thisSess);
        mainRunList = fs_fun_readrun('main_loc.txt', project, thisSess);
        
        runList = [locRunList; mainRunList];  % run list for both
        runList = runList(~cellfun(@isempty, runList));  % remove empty cell
        
    elseif ischar(runFolder)
        runList = {runFolder};
    end
    
    % number of runs 
    nRun = numel(runList);
    for iRun = 1:nRun
        
        thisRun = runList{iRun};
        thisFile = fullfile(theBoldPath, thisRun);
        
        % freesurfer command to do the automatic registration        
        fscmd = sprintf('bbregister --mov %1$s/template.nii.gz --bold --s %2$s --lta %1$s/register.lta',...
            thisFile, thisSubjCode);
        system(fscmd);
        
    end
end

end