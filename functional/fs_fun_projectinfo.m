function projStr = fs_fun_projectinfo(projectName, funcPath, boldext)
% This function creates the structure for a project
%
% Inputs:
%    projectName       name of the project (which is usually the first part
%                      of subject codes in the functional folder)
%    funcPath          the path of functional data
%    boldext           the extension (usually is '_self')
% Output:
%    a structure of project information
%
% Creatd by Haiyang Jin (18/12/2019)

% Copy information from FreeSurfer
FS = fs_subjdir;
projStr.subjects = FS.subjects;

if nargin < 2 || isempty(funcPath)
    funcPath = fullfile(FS.subjects, '..', 'functional_data/');
end
if nargin < 3 
    boldext = '_self';
end

% set the environmental variable of FUNCTIONALS_DIR
setenv('FUNCTIONALS_DIR', funcPath);

% add underscore if there is not available in boldext
if ~isempty(boldext) &&~strcmp(boldext(1), '_')
    boldext = ['_', boldext];
end

projStr.boldext = boldext;
projStr.funcPath = funcPath;
projStr.hemis = FS.hemis;
projStr.nHemi = FS.nHemi;

% bold subject codes
tmpDir = dir(fullfile(projStr.funcPath, [projectName, '*', boldext]));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

projStr.subjdir = tmpDir(isSubDir);
projStr.subjList = {projStr.subjdir.name};
projStr.nSubj = numel(projStr.subjList);

end