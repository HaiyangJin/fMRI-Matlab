function fs_cvn_print2nd(sigPathInfo, sigFn, outPath, extraopts)
% fs_cvn_print2nd(sigPath, [sigFn = 'perm.th30.abs.sig.cluster.nii.gz', ..
%   outPath=pwd, extraopts={}])
%
% This function prints the results of second level (group level) analysis.
% 'perm.th30.abs.sig.cluster.nii.gz' usually is the significant clusters
% after multiple comparison corrections and 'sig.nii.gz' is the "raw"
% p-values before corrections.
%
% Inputs:
%    sigPathInfo    <cell> a 1xQ or Px1 cell. All the path and filename
%                    information to theto-be-printed files. Each row is
%                    one layer (level) ofthe path and all the paths will
%                    be combined in order(with all possible combinations).
%                    [fileInfo will be dealt with fs_fullfile.m]
%    sigFn          <string> the filename of the cluster p value file
%                    (e.g., perm.th30.abs.sig.cluster.nii.gz by default).
%    outPath        <string> where to save the output images. [current
%                    folder by default].
%    extraopts       extra options for cvnlookupimages.m
%
% Output:
%    images of group-level results saved at outPath.
%
% Example:
% sigPathInfo = {
%     'group';  % group folders
%     {'analysis1', 'analysis2'};
%     {'contrast1', 'contrast2', 'contrast3'};
%     'glm-group';
%     'osgm'};
%
% Created by Haiyang Jin (13-Apr-2020)

%% Deal with input

% make the path
sigPath = fs_fullfile(sigPathInfo{:});

% whether the sigPath exist
isExist = cellfun(@(x) exist(x, 'file'), sigPath);
isFullPath = cellfun(@(x) startsWith(x, filesep), sigPath);
needsFull = ~isExist & ~isFullPath;

if any(needsFull)
    sigPath(needsFull) = fullfile(getenv('FUNCTIONALS_DIR'), sigPath(needsFull));
end

isExist = cellfun(@(x) exist(x, 'dir'), sigPath);
if any(~isExist)
    noFiles = sigPath(~isExist);
    error('Cannot find the path: %s.\n', noFiles{:});
end

% the significance file
if ~exist('sigFn', 'var') || isempty(sigFn)
    sigFn = 'perm.th30.abs.sig.cluster.nii.gz';
end
assert(ischar(sigFn), '''sigFn'' has to be a string.');

% output path
if ~exist('outPath', 'var') || isempty(outPath)
    outPath = fullfile(pwd, 'Group_level_results');
end
outPath = fullfile(outPath, sigFn);
if ~exist(outPath, 'dir'); mkdir(outPath); end

if ~exist('extraopts', 'var') || isempty(extraopts)
    extraopts = {};
end

% the full path to the sig files
thefiles = fullfile(sigPath, sigFn);

% only keep the files for left hemisphere
leftFiles = thefiles(:); % make sure theFiles is only one column
leftFiles(contains(leftFiles, 'rh')) = [];
% find the corresponding files for right hemisphere
rightFiles = strrep(leftFiles, 'lh', 'rh');

% combine files for left and right hemispheres
surfs = [leftFiles, rightFiles];

% read the file into structure(s)
surfStruct = arrayfun(@(x) fs_cvn_valstruct(surfs(x, :)), ...
    1:size(surfs, 1), 'uni', false);

% calculate the maximum of the absolute data values
tempMax = max(cellfun(@(x) max(abs(x.data)), surfStruct));

% use the minimum 5*Integer as the maximum limit
climMax = ceil(tempMax/5)*5;

% generate figures
clim0 = [-climMax climMax];
cmap0 = jet(256);  % use jet(256) as the colormap
thresh0 = 1.3010i;  % absolute value of 1.3 (p = 0.05)
lookup = [];
wantfig = 2;  % do not show figure with fs_cvn_lookuplmv.m

extraopts = [extraopts, {'cmap', cmap0, 'clim', clim0}];

nSurf = size(surfs, 1);
for iSurf = 1: nSurf
    
    % print message
    fprintf('Printing the results [%d/%d] ...\n', iSurf, nSurf);
    
    % this pair of surfaces
    valstruct = surfStruct{iSurf};
    
    % generate figures for this pair
    [lookup, rgbimg] = fs_cvn_lookuplmv('fsaverage', 1, valstruct, ...
        thresh0, lookup, wantfig, extraopts);
    
    % set the figure name and save it
    fig = figure('Visible','off');
    imshow(rgbimg); % display lookup results (imagesc + colorbar)
    
    % obtain the contrast name as the figure name
    theConName = unique(cellfun(@(x) fs_2contrast(x, filesep), surfs(iSurf, :), 'uni', false));
    set(fig, 'Name', theConName{1});
    
    colorbar;
    colormap(cmap0);
    caxis(clim0);
    
    thisOut = fullfile(outPath, [theConName{1} '.png']);
    % print the figure
    try
        % https://github.com/altmany/export_fig
        export_fig(thisOut, '-png','-transparent','-m2');
    catch
        print(fig, thisOut,'-dpng');
    end
    
end

% save the filenames of the data file
thesurfs = surfs';
fs_createfile(fullfile(outPath, 'group.log'), thesurfs(:));

end