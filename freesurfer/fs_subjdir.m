function [struDir, subjList] = fs_subjdir(struDir, strPattern, setdir)
% [struDir, subjList] = fs_subjdir(struDir, strPattern, setdir)
%
% This function set up '$SUBJECTS_DIR' and output the subject code list.
%
% Input:
%    struDir        <str> path to $SUBJECTS_DIR folder in FreeSurfer.
%    strPattern     <str> string pattern used to identify subject
%                    folders.
%    setdir         <boo> 1 [default]: setenv SUBJECTS_DIR; 0: do not
%                    set env.
%
% Output:
%    struDir        <str> path to the structural folder.
%    subjList       <cell str> a list of subject codes.
%    save struDir to $SUBJECTS_DIR if applicable.
%
% Created by Haiyang Jin (2020-01-16)

% Default path to SUBJECTS_DIR
if ~exist('struDir', 'var') || isempty(struDir)
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
    % make sure the struDir exists
    assert(logical(exist(struDir, 'dir')), ...
        'Cannot find the directory: \n%s...', struDir);
    setenv('SUBJECTS_DIR', fm_2cmdpath(struDir));
    fprintf('SUBJECTS_DIR is set as %s now...\n', getenv('SUBJECTS_DIR'));
end

% subject code information
tmpDir = dir(fullfile(struDir, strPattern));
isSubDir = [tmpDir.isdir] & ~ismember({tmpDir.name}, {'.', '..'});

subjDir = tmpDir(isSubDir);
subjList = {subjDir.name};

end
