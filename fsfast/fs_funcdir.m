function [funcDir, sessList] = fs_funcdir(funcDir, strPattern, setdir)
% [funcDir, sessList] = fs_funcdir(funcDir, strPattern)
%
% This function sets $FUNCTIONALS_DIR in FreeSurfer.
%
% Inputs:
%    funcDir          <str> the path to functional data. This path will
%                      also be saved as FUNCTIONALS_DIR.
%    strPattern       <str> wildcard strings for identifying session names.
%                      It will be used to identify all the sessions. E.g.,
%                      it can be "Face*" (without quotes).
%    setdir           <boo> 1 [default]: setenv SUBJECTS_DIR; 0: do not
%                      set env.
%
% Output:
%    funcDir          <str> path to the functional folder.
%    sessList         <cell str> a list of session codes.
%    save funcDir to $FUNCTIONALS_DIR if applicable.
%
% Creatd by Haiyang Jin (18-Dec-2019)

if ~exist('funcDir', 'var') || isempty(funcDir)
    funcDir = getenv('FUNCTIONALS_DIR');
    if ~exist('setdir', 'var') || isempty(setdir); setdir = 0; end
end

if ~exist('strPattern', 'var') || isempty(strPattern)
    strPattern = '';
end

if ~exist('setdir', 'var') || isempty(setdir)
    setdir = 1;
end
if isempty(funcDir) && setdir
    error('Please set $FUNCTIONALS_DIR with fs_funcdir().')
end

% make sure the struDir exists
assert(logical(exist(funcDir, 'dir')), 'Cannot find the directory: \n%s...', funcDir);

% set the environmental variable of FUNCTIONALS_DIR
if setdir
    setenv('FUNCTIONALS_DIR', funcDir);
end

% sessions (bold subject codes)
tmpDir = dir(fullfile(funcDir, strPattern));
isSessDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

sessDir = tmpDir(isSessDir);
sessList = {sessDir.name}';

end