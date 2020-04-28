function fs_cvn_print2nd(sigPathInfo, sigFn, outPath, varargin)
% fs_cvn_print2nd(sigPath, [sigFn = 'perm.th30.abs.sig.cluster.nii.gz', ..
%   outPath=pwd, extraopts={}])
%
% This function prints the results of second level (group level) analysis.
% 'perm.th30.abs.sig.cluster.nii.gz' usually is the significant clusters
% after multiple comparison corrections and 'sig.nii.gz' is the "raw"
% p-values before corrections.
%
% Inputs:
%    sigPathInfo     <cell> a 1xQ or Px1 cell. All the path and filename
%                     information to theto-be-printed files. Each row is
%                     one layer (level) ofthe path and all the paths will
%                     be combined in order(with all possible combinations).
%                     [fileInfo will be dealt with fs_fullfile.m]
%    sigFn           <string> the filename of the cluster p value file
%                     (e.g., perm.th30.abs.sig.cluster.nii.gz by default).
%    outPath         <string> where to save the output images. [current
%                     folder by default].
%
% Optional inputs (varargin):
%    'viewpt'        <integer> the viewpoitns to be used. More see
%                     fs_cvn_lookup.m. Default is -2.
%    'thresh'        <numeric> display threshold. Default is 1.3010 (abs).
%    'clim'          <numeric array> limits for the color map. The Default
%                     empty, which will display responses from %1 to 99%.
%    'cmap'          <> use which color map, default is jet.
%    'lookup'        <> setting used for cvnlookupimage.
%    'annot'         <string> which annotation will be used. Default is
%                     '', i.e., not display annotation file.
%    'wantfig'       <logical/integer> Default is 2, i.e., do not show the
%                     figure. More please check fs_cvn_lookup.
%    'cvnopts'       <cell> extra options for cvnlookupimages.m.
%    'funcPath'      <string> the path to functional folder [Default is
%                     $FUNCTIONALS_DIR].
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

defaultOpts = struct(...
    'viewpt', -2, ...
    'thresh', 1.3010i, ...
    'clim', [], ...
    'cmap', jet(256), ...
    'lookup', [], ...
    'annot', '', ...
    'wantfig', 2, ...
    'cvnopts', {{}}, ...
    'funcpath', getenv('FUNCTIONALS_DIR'), ... % not in use now
    'strupath', getenv('SUBJECTS_DIR')); % not in use now

options = fs_mergestruct(defaultOpts, varargin);


viewpt = options.viewpt;
thresh = options.thresh;  % absolute value of 1.3 (p = 0.05)
clim = options.clim;
cmap = options.cmap;  % use jet(256) as the colormap
lookup = options.lookup;
annot = options.annot;
wantfig = options.wantfig;  % do not show figure with fs_cvn_lookuplmv.m
cvnopts = options.cvnopts;

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

%% Read files
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

% Calculate the colorbar limit if it is empty
if isempty(clim)
    % calculate the maximum of the absolute data values
    tempMax = max(cellfun(@(x) max(abs(x.data)), surfStruct));
    
    % use the minimum 5*Integer as the maximum limit
    climMax = ceil(tempMax/5)*5;
    
    % generate figures
    clim0 = [-climMax climMax];
else
    clim0 = clim;
end

%% Create figure for every surf
nSurf = size(surfs, 1);
for iSurf = 1: nSurf
    
    % print message
    fprintf('Printing the results [%d/%d] ...\n', iSurf, nSurf);
    
    % this pair of surfaces
    valstruct = surfStruct{iSurf};
    
    % generate figures for this pair
    [~, lookup, rgbimg] = fs_cvn_lookup('fsaverage', viewpt, valstruct, ...
        lookup, 'cvnopts', [cvnopts, {'cmap', cmap, 'clim', clim0}], ...
                'wantfig', wantfig, ...
                'thresh', thresh, ...
                'annot', annot); 
            
    % set the figure name and save it
    fig = figure('Visible','off');
    imshow(rgbimg); % display lookup results (imagesc + colorbar)
    
    % obtain the contrast name as the figure name
    theConName = unique(cellfun(@(x) fs_2contrast(x, filesep), surfs(iSurf, :), 'uni', false));
    set(fig, 'Name', theConName{1});
    
    colorbar;
    colormap(cmap);
    caxis(clim0);
    
    thisOut = fullfile(outPath, [theConName{1} '.png']);
    % print the figure
    try
        % https://github.com/altmany/export_fig
        export_fig(thisOut, '-png','-transparent','-m2');
    catch
        print(fig, thisOut,'-dpng');
    end
    
    close(fig);
end

% save the filenames of the data file
thesurfs = surfs';
fs_createfile(fullfile(outPath, 'group.log'), thesurfs(:));

end