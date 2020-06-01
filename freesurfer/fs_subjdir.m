function [struPath, subjList] = fs_subjdir(struPath, strPattern, setdir)
% [struPath, subjList] = fs_subjdir(struPath, strPattern, setdir)
%
% This function set up 'SUBJECTS_DIR' and output the subject code list.
%
% Input:
%    struPath       <string> path to $SUBJECTS_DIR folder in FreeSurfer.
%    strPattern     <string> string pattern used to identify subject
%                    folders.
%    setdir         <logical> 1 [default]: setenv SUBJECTS_DIR; 0: do not
%                    set env.
%
% Output:
%    struPath       <string> path to the structural folder.
%    subjList       <cell of strings> a list of subject codes.
%    save struPath to $SUBJECTS_DIR if applicable.
%
% Created and updated by Haiyang Jin (16-Jan-2020)

% Default path to SUBJECTS_DIR
if ~exist('struPath', 'var') || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
    setdir = 0;
end

if ~exist('strPattern', 'var') || isempty(strPattern)
    strPattern = '';
end

if ~exist('setdir', 'var') || isempty(setdir)
    setdir = 1;
end

if setdir
    setenv('SUBJECTS_DIR', struPath);
    fprintf('SUBJECTS_DIR is set as %s now...\n', struPath);
end

% subject code information
tmpDir = dir(fullfile(struPath, strPattern));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

subjDir = tmpDir(isSubDir);
subjList = {subjDir.name};

end
