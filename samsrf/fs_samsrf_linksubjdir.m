function fs_samsrf_linksubjdir(sourcePath, targetPath, isLink, force)
% This function links the structPath (source) to the session folder in the 
% functional data folder (target).
%
% Inputs:
%     sourcePath         <string> the path to the source folder. [usually
%                        should be the sessCode folder in funcPath.]
%     targetPath         <string> the path to the target folder. [usually
%                        should be the subjCode in structPath.
%     isLink             <logical> if link the two folder. 1 (default): 
%                        link folder; 0: copy folder.
%     force              <logical> if force, the target folders will be
%                        removed if they already exist.
%     
% Output:
%     link or copy folders.
%
% Folders to be linked/copied:
%     label, mri, scripts, stats, surf, tmp, touch, trash
%
% Created by Haiyang Jin (15-Feb-2020)

if nargin < 3 || isempty(isLink)
    isLink = 1;
end

if nargin < 4 || isempty(force)
    force = 0;
end

% read folders in the source path
sourceDir = dir(sourcePath);
sourceDir(startsWith({sourceDir.name}, '.')) = [];

% make sure the targetPath is a cell
if ischar(targetPath); targetPath = {targetPath}; end

if isLink
    sourceFolders = fullfile({sourceDir.folder}, {sourceDir.name});
    
    % link folders
    tempfunc = @(x, y) system(sprintf('ln -s %s %s', x, y));
    
else
    % create all the combinations of source and target
    sourceFolders = unique({sourceDir.folder});
    
    % copy folders
    tempfunc = @copyfile;
end

% create all the combinations of source and target
[tempSource, tempTarget] = ndgrid(sourceFolders, targetPath);

if force % && isLink
    % remove the target folder if it exists
    
    % the path to all the target subfolders
    [targetTemp, targetSub] = ndgrid(targetPath, {sourceDir.name});
    theTarget = fullfile(targetTemp, targetSub);
    
    % delete these folders
    cellfun(@delete, unique(theTarget));
end

% run the function
cellfun(tempfunc, tempSource, tempTarget);

end