function sessList = fs_funcdir(funcPath, strPattern)
% sessList = fs_funcdir(funcPath, strPattern)
%
% This function creates the structure for a project.
%
% Inputs:
%    funcPath         <string> the path to functional data. This path will
%                      also be saved as FUNCTIONALS_DIR.
%    strPattern       <string> the string pattern for session names. It
%                      will be used to identify all the sessions. E.g., it
%                      can be "Face*" (without quotes).
%
% Output:
%    sessList         <cell of strings> a list of session codes.
%    save funcPath to $FUNCTIONALS_DIR if applicable.
%
% Creatd by Haiyang Jin (18-Dec-2019)

if nargin < 1 || isempty(funcPath)
    
    if isempty(getenv('FUNCTIONALS_DIR'))
        % if FUNCTIONALS_DIR is not set, use the default folder (not reliable)
        funcPath = fullfile(getenv('SUBJECTS_DIR'), '..', 'functional_data');
    else
        funcPath = getenv('FUNCTIONALS_DIR');
    end
end

if nargin < 2 || isempty(strPattern)
    strPattern = '';
end

% set the environmental variable of FUNCTIONALS_DIR
setenv('FUNCTIONALS_DIR', funcPath);

% sessions (bold subject codes)
tmpDir = dir(fullfile(funcPath, strPattern));
isSessDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

sessDir = tmpDir(isSessDir);
sessList = {sessDir.name}';

end