function fs_samsrf_linksubjdir(subjdir, trgdir, toLink, force)
% fs_samsrf_linksubjdir(subjdir, trgdir, toLink, force)
%
% Make simlink for the sujbect folder in $SUBJECTS_DIR (`subjdir`) to the 
% session folder for SamSrf (`trgdir`).
%
% Inputs:
%     subjdir           <str> the path to the subject code folder in 
%                        $SUBJECTS_DIR, e,g., $SUBJECTS_DIR/sub-101.
%     trgdir            <str> the path to the session folder in 
%                        $SAMSRF_DIR, e.g., $SAMSRF_DIR/sub-101_ses-01.
%     toLink            <bool> if link the two folder. 1 (default): 
%                        link folder; 0: copy folder.
%     force             <bool> if force, the target folders will be
%                        removed if they already exist.
%     
% Output:
%     link or copy folders.
%
% Folders to be linked/copied:
%     label, mri, scripts, stats, surf, tmp, touch, trash
%
% Created by Haiyang Jin (15-Feb-2020)

fm_mkdir(trgdir);

if ~exist('toLink', 'var') || isempty(toLink)
    toLink = 1;
end

if ~exist('force', 'var') || isempty(force)
    force = 0;
end

% read folders in the source path
srcDir = dir(subjdir);
srcDir(startsWith({srcDir.name}, '.')) = [];

% make sure the targetPath is a cell
if ischar(trgdir); trgdir = {trgdir}; end

if toLink
    sourceFolders = fullfile({srcDir.folder}, {srcDir.name});
    
    % link folders
    tmpfunc = @(x, y) system(sprintf('ln -s %s %s', x, y));
    
else
    % create all the combinations of source and target
    sourceFolders = unique({srcDir.folder});

    % copy folders
    tmpfunc = @copyfile;
end

% create all the combinations of source and target
    [tmpSrc, tmpTrg] = ndgrid(sourceFolders, trgdir);

if force % && toLink
    % remove the target folder if it exists
    
    % the path to all the target subfolders
    [trgTmp, trgSub] = ndgrid(trgdir, {srcDir.name});
    theTarget = fullfile(trgTmp, trgSub);
    
    % delete these folders
    cellfun(@delete_force, unique(theTarget));
end

% run the function
cellfun(tmpfunc, fm_2cmdpath(tmpSrc), tmpTrg);

end

function delete_force(thedir)

if exist(thedir, 'dir')
    delete(thedir);
    fprintf('The directory (%s) is deleted...\n', thedir);
end
end

