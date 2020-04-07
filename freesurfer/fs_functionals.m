function project = fs_functionals(sessStrPattern, funcPath)
% project = fs_functionals(funcPath, sessStr)
%
% This function creates the structure for a project.
%
% Inputs:
%    sessStrPattern   <string> the string pattern for session names. It
%                      will be used to identify all the sessions.
%    funcPath         <string> the path to functional data. This path will
%                      also be saved as FUNCTIONALS_DIR.
%
% Output:
%    project           a structure of project information
%
% Creatd by Haiyang Jin (18-Dec-2019)

% Copy information from FreeSurfer
project = fs_subjdir;

if nargin < 2 || isempty(funcPath)
    funcPath = fullfile(project.structPath, '..', 'functional_data');
end

% set the environmental variable of FUNCTIONALS_DIR
setenv('FUNCTIONALS_DIR', funcPath);
project.funcPath = funcPath;

% sessions (bold subject codes)
tmpDir = dir(fullfile(project.funcPath, sessStrPattern));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

project.sessDir = tmpDir(isSubDir);
project.sessList = {project.sessDir.name};
project.nSess = numel(project.sessList);

end