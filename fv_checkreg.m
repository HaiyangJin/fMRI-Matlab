function fv_checkreg(project, sessCode, loadReg, runFolder)
% fv_checkreg(project, sessCode, loadReg, runFolder)
%
% This function displays the co-registration between structure and
% functional data in FreeView.
%
% Inputs:
%     project           project information (created by fs_fun_projectinfo)
%     sessCode          <string> session code in functional folder 
%     loadReg           <logical> 1: load the register.lta in the folder;
%                       0: do not load the file. (register.lta is generated
%                       by fs_bbregister.m which performs the automatic
%                       registration.)
%     runFolder         <string> the run folder names
%
% Output:
%     display the registration (before or after bbregister)
%
% Created by Haiyang Jin (22-Jan-2020)

if nargin < 3 || isempty(loadReg)
    loadReg = 0;  % don't load the register.lta by default
end

if nargin < 4 || isempty(runFolder)
    % show the first run by default
    locList = fs_fun_readrun('run_loc.txt', project, sessCode);
    mainList = fs_fun_readrun('run_main.txt', project, sessCode);
    runList = [locList; mainList];
    runFolder = runList{1};
end

% the template filename
tempFile = fullfile(project.funcPath, sessCode, 'bold', runFolder, 'template.nii.gz');

% subject code in SUBJECTS_DIR
subjCode = fs_subjcode(sessCode, project.funcPath);

% display the template.nii.gz with ?h.white and ?h.pial
fv_volmgz(tempFile, subjCode, project.structPath, '', loadReg);

end