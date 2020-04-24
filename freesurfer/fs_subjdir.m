function [struPath, subjList] = fs_subjdir(struPath, strPattern)
% function subjList = fs_subjdir(struPath, strPattern)
%
% This function set up 'SUBJECTS_DIR' and output the subject code list.
%
% Input:
%    struPath       <string> path to $SUBJECTS_DIR folder in FreeSurfer.
%    strPattern     <string> string pattern used to identify subject
%                    folders.
%
% Output:
%    struPath       <string> path to the structural folder.
%    subjList       <cell of strings> a list of subject codes.
%    save struPath to $SUBJECTS_DIR if applicable.
%
% Created and updated by Haiyang Jin (16-Jan-2020)

% Default path to SUBJECTS_DIR
if nargin < 1 || isempty(struPath)
    struPath = getenv('SUBJECTS_DIR');
else
    setenv('SUBJECTS_DIR', struPath);
end

if nargin < 2 || isempty(strPattern)
    strPattern = '';
end

% subject code information
tmpDir = dir(fullfile(struPath, strPattern));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

subjDir = tmpDir(isSubDir);
subjList = {subjDir.name};

end
