function fs_bbregister(sessList, runList, funcPath)
% fs_bbregister(sessList, runList, funcPath)
%
% This function does the automatic registration between the tempalte.nii.gz
% and the structure. For more information, please check
% https://surfer.nmr.mgh.harvard.edu/fswiki/MultiModalTutorialV6.0/MultiModalRegistration.
%
% Inputs:
%    sessList          <cell of string> or <string> session code in
%                       $FUNCTIONALS_DIR.
%    runFolder         <string> the run folder names
%    funcPath          <string> the full path to the functional folder.
%
% Output:
%     create files named 'register.lta' and 'register.dat'.
%
% Created by Haiyang Jin (20-Jan-2020)

if ischar(sessList)
    sessList = {sessList};
end

if nargin < 3 || isempty(funcPath)
    funcPath = getenv('FUNCTIONALS_DIR');
end

nSess = numel(sessList);
for iSess = 1:nSess
    
    thisSess = sessList{iSess};
    thisSubjCode = fs_subjcode(thisSess, funcPath);
    theBoldPath = fullfile(funcPath, thisSess, 'bold');
    
    % get the run list
    if nargin < 2 || isempty(runList)  % all runs
        % get the list of run folders (with numbers only)
        locRunList = fs_readrun('run_loc.txt', thisSess, funcPath);
        mainRunList = fs_readrun('main_loc.txt', thisSess, funcPath);
        
        runList = [locRunList; mainRunList];  % run list for both
        runList = runList(~cellfun(@isempty, runList));  % remove empty cell
        
    elseif ischar(runList)
        runList = {runList};
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