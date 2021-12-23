function fv_checkreg(sessCode, loadReg, runFolder, funcDir, struDir)
% fv_checkreg(sessCode, loadReg, runFolder, funcDir, struDir)
%
% This function displays the co-registration between structure and
% functional data in FreeView.
%
% Inputs:
%     sessCode          <str> session code in functional folder 
%     loadReg           <boo> 1: load the register.lta in the folder;
%                        0: do not load the file. (register.lta is generated
%                        by fs_bbregister.m which performs the automatic
%                        registration.)
%     runFolder         <str> or <num> the run folder names (or
%                        order).
%     funcDir           <str> $FUNCTIONALS_DIR
%     subjDir           <str> $SUBJECTS_DIR
%
% Output:
%     display the registration (before or after bbregister)
%
% Created by Haiyang Jin (22-Jan-2020)

if nargin < 2 || isempty(loadReg)
    loadReg = 0;  % don't load the register.lta by default
end

if nargin < 3 || isempty(runFolder)
    % show the first run by default
    runFolder = 1;
end

if nargin < 4 || isempty(funcDir)
    funcDir = getenv('FUNCTIONALS_DIR');
end

if nargin < 5 || isempty(struDir)
    struDir = '';
end

if isnumeric(runFolder)
    % get the run list
    locList = fs_readrun('run_loc.txt', sessCode);
    mainList = fs_readrun('run_main.txt', sessCode);
    runList = [locList; mainList];
    runFolder = runList{runFolder};
end

% the template filename
tempFile = fullfile(funcDir, sessCode, 'bold', runFolder, 'template.nii.gz');

% subject code in SUBJECTS_DIR
subjCode = fs_subjcode(sessCode);

% display the template.nii.gz with ?h.white and ?h.pial
fv_vol(tempFile, subjCode, struDir, '', loadReg);

end