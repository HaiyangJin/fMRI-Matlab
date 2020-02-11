function fs_copyfile(source, target, force)
% fs_copyfile(source, target, force)
% This function copies files. It will create the target direcotry if it does
% not exist.
%
% Inputs:
%     source            <string> source files or folder.
%     target            <string> target folder/path.
%     force             <logical> force to copy files regardless if they
%                       already exist in the target folder.
%
% Output:
%     copy files...
%
% Created by Haiyang Jin (11-Feb-2020)

if nargin < 3 || isempty(force)
    force = 0;
end

[~, sourceFn, sourceExt] = fileparts(source);
sourceFile = [sourceFn sourceExt];

isExist = 0;

% make the target direcotry if it does not exist
if ~exist(target, 'dir')
    mkdir(target);
elseif ~isempty(dir(fullfile(target, sourceFile)))
    % check if the source files already exist in the target folder
    isExist = 1;
    warning('File %s is already in Folder %s.', sourceFile, target);
end

if ~isExist || force
    % copy the files
    copyfile(source, target);
else
    warning('The source files are not copied to the target folder.');
end

end