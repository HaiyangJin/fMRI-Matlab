function fs_cvn_print2nd(sigPathInfo, sigFn, outPath, varargin)
% fs_cvn_print2nd(sigPath, [sigFn = 'perm.th30.abs.sig.cluster.nii.gz', ..
%   outPath=pwd, varargin])
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
%                     fs_cvn_lookup.m. Default is -1.
%    'thresh'        <numeric> display threshold. Default is 1.3010 (abs).
%    'clim'          <numeric array> limits for the color map. The Default
%                     empty, which will display responses from %1 to 99%.
%    'cmap'          <> use which color map, default is jet.
%    'lookup'        <> setting used for cvnlookupimage.
%    'outline'       <logical> whether show the outlines of clusters as
%                     different colors.
%    'outcolor'      <integer> 1: show the default color in fs_colors;
%                      0: show the default color in the corresponding
%                      annotation file.
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
%
% See also:
% fs_readsummary

%% Deal with inputs

defaultOpts = struct(...
    'viewpt', -1, ...
    'thresh', 1.3010i, ... % absolute value of 1.3 (p = 0.05)
    'clim', [], ...
    'cmap', jet(256), ...
    'lookup', [], ...
    'outline', 0, ...
    'outcolor', 1, ...
    'annot', '', ...
    'showinfo', 0, ...
    'wantfig', 2, ... % do not show figure with fs_cvn_lookuplmv.m
    'cvnopts', {{}}, ...
    'funcpath', getenv('FUNCTIONALS_DIR'), ...
    'strupath', getenv('SUBJECTS_DIR')); % not in use now

opts = fs_mergestruct(defaultOpts, varargin);

clim = opts.clim;
cmap = opts.cmap;  % use jet(256) as the colormap
lookup = opts.lookup;

showInfo = opts.showinfo;

% make the path for the sig files
sigPath = fs_fullfile(sigPathInfo{:});

% whether the sigPath exist
isExist1 = cellfun(@(x) ~isempty(dir(x)), sigPath);
isFullPath = cellfun(@(x) startsWith(x, filesep), sigPath);
needsFull = ~isExist1 & ~isFullPath;

if any(needsFull)
    sigPath(needsFull) = fullfile(opts.funcpath, sigPath(needsFull));
end

isExist2 = cellfun(@(x) exist(x, 'dir'), sigPath);
if any(~isExist2)
    noFiles = sigPath(~isExist2);
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
outPath = fullfile(outPath, sprintf('%s_%0.2f', sigFn, opts.thresh));
if ~exist(outPath, 'dir'); mkdir(outPath); end

%% Read sig files
% the full path to the sig files
thefiles = fullfile(sigPath, sigFn);

% only keep the files for left hemisphere
leftFiles = thefiles(:); % make sure theFiles is only one column
leftFiles(contains(leftFiles, 'rh')) = [];
% find the corresponding files for right hemisphere
rightFiles = strrep(leftFiles, 'lh', 'rh');

% combine files for left and right hemispheres
surfs = [leftFiles, rightFiles];
nSurf = size(surfs, 1);

% read the file into structure(s)
surfStruct = arrayfun(@(x) fs_cvn_valstruct(surfs(x, :)), ...
    1:nSurf, 'uni', false);

% Calculate the colorbar limit if it is empty
if isempty(clim)
    % calculate the maximum of the absolute data values
    tempMax = max(cellfun(@(x) max(abs(x.data)), surfStruct));
    
    % use the ceil of the maximum value as the maximum limit
    climMax = ceil(tempMax);
    
    % generate figures
    clim0 = [-climMax climMax];
else
    clim0 = clim;
end

%% Read other files if needed
% show the cluster outlines if needed
if opts.outline
    % show annotations (in the osgm/)
    annotFiles = cellfun(@(x) strrep(x, 'cluster.nii.gz', 'ocn.annot'), surfs, 'uni', false);
    [roiHemis, roicolortemp] = cellfun(@(x) fs_readannot(x, '', '', 1), annotFiles, 'uni', false);
    
    % complementary the other hemi (with all 0)
    zeroL = cellfun(@(x) x.numrh, surfStruct, 'uni', false);
    roitempL = cellfun(@(x1, x2) cellfun(@(y) [y; zeros(x2, 1)], x1, 'uni', false), ...
        roiHemis(:, 1), zeroL', 'uni', false);
    zeroR = cellfun(@(x) x.numlh, surfStruct, 'uni', false);
    roitempR = cellfun(@(x1, x2) cellfun(@(y) [zeros(x2, 1); y], x1, 'uni', false), ...
        roiHemis(:, 2), zeroR', 'uni', false);
    
    % all the cluster outlines
    roiall = cellfun(@vertcat, roitempL, roitempR, 'uni', false)';
    
    % use self defined colors in fs_colors
    if opts.outcolor
        roicolorL = cellfun(@(x) fs_colors(numel(x)*1i), roitempL, 'uni', false);
        roicolorR = cellfun(@(x) fs_colors(numel(x)*1i), roitempR, 'uni', false);
        roicolors = cellfun(@vertcat, roicolorL, roicolorR, 'uni', false);
    else
        roicolors = arrayfun(@(x) vertcat(roicolortemp{x, :}), 1:size(roicolortemp, 1), 'uni', false)';
    end
else
    roiall = repmat({[]}, nSurf, 1);
    roicolors = roiall;
end

% read the cluster information 
if showInfo
    % show the cluster information in *.summary if necessary
    sumFiles = cellfun(@(x) strrep(x, 'cluster.nii.gz', 'cluster.summary'), surfs, 'uni', false);
    sumHemiCell = arrayfun(@(x) fs_readsummary(x, 0, 'none'), sumFiles, 'uni', false);
    sumCell = arrayfun(@(x) vertcat(sumHemiCell{x, :}), 1:size(sumHemiCell, 1), 'uni', false)';
end

%% Create figure for every surf
for iSurf = 1: nSurf
    
    % print message
    fprintf('Printing the results [%d/%d] ...\n', iSurf, nSurf);
    
    % this pair of surfaces
    valstruct = surfStruct{iSurf};
    thisroi = roiall{iSurf};
    thisroicolor = roicolors{iSurf};
    
    % generate figures for this pair
    [~, lookup, rgbimg] = fs_cvn_lookup('fsaverage', opts.viewpt, valstruct, ...
        lookup, 'cvnopts', [opts.cvnopts, {'cmap', cmap, 'clim', clim0}], ...
        'wantfig', opts.wantfig, ...
        'thresh', opts.thresh, ...
        'roimask', thisroi, ...
        'roicolor', thisroicolor, ...
        'roiwidth', {0.5}, ...
        'annot', opts.annot);
    close all;
    
    % set the figure name and save it
    fig = figure('Visible','off');
    imshow(rgbimg); % display lookup results (imagesc + colorbar)
    
    % obtain the contrast name as the figure name
    theConName = unique(cellfun(@(x) fs_2contrast(x, filesep), surfs(iSurf, :), 'uni', false));
    set(fig, 'Name', theConName{1});
    
    % Load and show the group (second) level results information
    if showInfo 

        sumTable = sumCell{iSurf};
        sumTable.WghtVtx = [];
        sumTable.Hemi = [];
        
        pos = get(fig, 'Position'); %// gives x left, y bottom, width, height
        set(fig, 'Position', [pos(1:2) max(1050, pos(3)) pos(4)+max(pos(4)/pos(3)*1000-600, 200)]);
        % Get the table in string form.
        TString = evalc('disp(sumTable)');
        % Use TeX Markup for bold formatting and underscores.
        TString = strrep(TString,'<strong>','\bf');
        TString = strrep(TString,'</strong>','\rm');
        TString = strrep(TString,'_','\_');
        % Get a fixed-width font.
        FixedWidth = get(0,'FixedWidthFontName');
        % Output the table using the annotation command.
        annotation(gcf,'Textbox','String',TString,'Interpreter','Tex',...
            'FontName',FixedWidth,'Units','Normalized',...
            'Position',[0.01 0 1 0.1],'FontSize',12,'LineStyle','none');
    end
    
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