function [struDir, subjList] = fs_subjdir(struDir, strPattern, setdir)
% [struPath, subjList] = fs_subjdir(struPath, strPattern, setdir)
%
% This function set up 'SUBJECTS_DIR' and output the subject code list.
%
% Input:
%    struDir       <string> path to $SUBJECTS_DIR folder in FreeSurfer.
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
if ~exist('struPath', 'var') || isempty(struDir)
    struDir = getenv('SUBJECTS_DIR');
    setdir = 0;
end

if ~exist('strPattern', 'var') || isempty(strPattern)
    strPattern = '';
end

if ~exist('setdir', 'var') || isempty(setdir)
    setdir = 1;
end

% my secrect default path to 'fsaverage'
if strcmp(struDir, 'myfs')
    struDir = fullfile('Volumes', 'GoogleDrive', 'My Drive', '102_fMRI', 'MRI_Template');
end

if setdir
    % make sure the struPath exists
    assert(logical(exist(struDir, 'dir')), ...
        'Cannot find the directory: \n%s...', struDir);
    setenv('SUBJECTS_DIR', struDir);
    fprintf('SUBJECTS_DIR is set as %s now...\n', struDir);
end

% subject code information
tmpDir = dir(fullfile(struDir, strPattern));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

subjDir = tmpDir(isSubDir);
subjList = {subjDir.name};

end
