function project = fs_fun_projectinfo(projectName, funcPath, boldext)
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
project = fs_subjdir;

if nargin < 2 || isempty(funcPath)
    funcPath = fullfile(project.strcutPath, '..', 'functional_data/');
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

project.boldext = boldext;
project.funcPath = funcPath;

% sessions (bold subject codes)
tmpDir = dir(fullfile(project.funcPath, [projectName, '*', boldext]));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

project.sessDir = tmpDir(isSubDir);
project.sessList = {project.sessDir.name};
project.nSess = numel(project.sessList);

end