function varargout= fs_cvn_lookup(trgSubj,viewIdx,valstruct,lookups,varargin)
% [rawimg, lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj,view,valstruct,...
%    [lookups, varargin])
%
% This function uses (copies) cvn codes to plot surface data on lateral,
% medial, and ventral viewpoints at the same time. When the viewIdx is
% positive integer, you can also draw ROI [please check <himg> below].
%
% Inputs:
%    trgSubj          <string> whose coordiantes will be used for plotting.
%    viewIdx          <integer> which views are used to display the
%                      results. More see below.
%    valstruct        <struct> struct('data',<L+R x 1>,'numlh',L,'numrh',R)
%                      to create images for both hemispheres side by side.
%                      In this case, hemi, view_az_el_tilt, and Lookup must
%                      be cell arrays. [if valstruct is 'nodata', no data
%                      will be displayed on the image (i.e., the brain
%                      only); 'nodatalh' only displays left hemisphere;
%                      'nodatarh' only displays right hemisphere.];
%                      fs_cvn_valstruct is also helpful.
%    lookups          <struct> the Lookup to re-use.
%
% Varargin:
%    'wantfig'        <logical/integer> whether to show a figure. 1: show
%                      figure (default); 2: do not show figure, but output
%                      himg.
%    'annot'          <string> name of the annotation files. e.g., 'aparc',
%                      'aparc.a2009s', 'aparc.a2005s'
%    'annotwidth'     <numeric> the width of the annotation lines.
%    'annotname'      <cell string> list of parcellation names in 'aparc'.
%                      e.g. 'fusiform' for 'aparc' (in 'annot'). To get the
%                      list of the names for certain annotation, you may
%                      try [~, ~, roiList] = fs_readannot('lh.aparc');
%    'thresh'         <numeric> real number for numbers with sign and
%                      non-real number is treated as abosolute threshold.
%    'clim'           <numeric array> limits for the color map. The Default
%                     empty, which will display responses from %1 to 99%.
%    'cmap'           <string or colormap array> use which color map, 
%                      default is jet(256). 
%                     'fsheatscale': use the heatscale in FreeSurfer and
%                      use 'fminmax' as the boundary.
%    'fminmax'        <numeric vector> 1x2 vector. will be used when 'cmap'
%                      is 'fsheatscale'. It will cover 'clim' and 'thresh'.
%    'roimask'        <cell numeric> Vx1 binary mask (or cell array for
%                      multiple ROIs) for an ROI to draw on final RGB image.
%                      For more plese check cvnlookupimages.m. IMPORTANT:
%                      to display annotations, roi mask has to be set here.
%    'roiwidth'       <numeric vector> width for the roi contour.
%    'roicolor'       <numeric array> ColorSpec or RGB color for ROI outline(s).
%    'cvnopts'        <cell> extra options used in cvnlookupimages.m,
%                      i.e., varargin in cvnlooupimages. [all settings here
%                      will overwrite the above settings in cvnlookupimagrs.m
%    ...              <For more> please check cvnlookupimages.m.
%
% Output (varargout):
%    rawimg           <> We can directly call imagesc on rawimg. This might
%                      be useful for quickly playing around with colormaps
%                      and color ranges.
%                 e.g. figure; imagesc(rawimg,[0 25]); colormap(jet(256)); axis image;
%    lookup:          <struct> Structure containing lookup information.
%                      Can speed up multiple lookups with the same viewpoint.
%                  OR <cell array> if two hemis provided in input.
%    rgbimg:          <numeric array> output containing RGB image:
%                      <res>x<res>x3.
%    himg             <image handle> can be used to draw ROI with:
%                 e.g. Rmask = drawroipoly(himg,Lookup);
%
%
% % Example 1: show random activations on both hemispheres with view 1
% fs_cvn_lookup('fsaverage', 3);
%
% % Example 2: show random activations on left hemisphere with view 1
% valstruct.numlh = 163842;  % This number is not arbitrary.
% valstruct.numrh = 0;
% valstruct.data = randn(valstruct.numlh,1);
% fs_cvn_lookup('fsaverage', 3, valstruct);
%
% % Example 3: show brain only (no data)
% fs_cvn_lookup('fsaverage', -1, 'nodata');
%
% % Example 4: show annotations without data
% fs_cvn_lookup('fsaverage', 3, 'nodatalh', [], 'annot', 'aparc');
%
% % Example 5: only show annotation for fusiform area with aparc
% fs_cvn_lookup('fsaverage', 3, 'nodatarh', [], 'annot', 'aparc', ...
%    'annotname', 'fusiform');
%
% % Example 6: add colorbar and change colormap (after showing the plots)
% colorbar;
% colormap jet
%
% % Example 7: test new viewpt;
% fs_cvn_lookup('fsaverage', {[270, -89, 0], [90, -89, 0]})
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% View options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% View indices (Part 1, multiple views):
%  -1  vertical layout (one column): lateral, medial, ventrcal;
%  -2  two columns: first: lateral, medial, ventrcal;
%                    second: frontal, occipital;
%  -3  vertical layout (one column): frontal, occipital;
%
% View indices (part 2, single view) [from cvnlookup]:
%      VIEWPOINT        SURFACE            HEMIFLIP  RES  FSAVG      XYEXTENT
%  1 {'occip'           'sphere'                   0 1000    0         [1 1]} ...
%  2 {'occip'           'inflated'                 0  500    0         [1 1]} ...
%  3 {'ventral'         'inflated'                 1  500    0         [1 1]} ...
%  4 {'parietal'        'inflated'                 0  500    0         [1 1]} ...
%  5 {'medial'          'inflated'                 0  500    0         [1 1]} ...
%  6 {'lateral'         'inflated'                 0  500    0         [1 1]} ...
%  7 {'medial-ventral'  'inflated'                 0  500    0         [1 1]} ...
%  8 {'ventral'         'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
%  9 {''                'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
% 10 {''                'full.flat.patch.3d'       0 1500    1         [290 0]} ...   % 5.17 pixels per mm
% 11 {'ventral-lateral' 'inflated'                 1 1000    0         [1 1]} ...
% 12 {'lateral-auditory' 'inflated'                0 1000    0         [1 1]} ...
% 13 {''                'full.flat.patch.3d'       0 1500    0         []} ...
% 14 {'superior'        'inflated'                 0  500    0         [1 1]} ...
% 15 {'frontal'         'inflated'                 0  500    0         [1 1]} ...
%    OR
% 'occipA1' through 'occipA8' where A can also be B or C
%    OR
% a fully specified cell vector with the options listed above. note that VIEWPOINT
% can take the format {viewpt viewhemis}. for example, consider the following:
% fs_cvn_lookup('subj01',{ {{[0 0 110] [0 0 -110]} {'lh' 'rh'}} 'full.flat.patch.3d' 0 1500 0 []}, ...
%             [],[],'cvnopts', {'savelookup',false});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Dependency:
%    cvn codes from Kendrick Kay:
%         https://github.com/kendrickkay/knkutils.git
%         https://github.com/kendrickkay/cvncode.git
%
% Created by Haiyang Jin (13-Apr-2020)

%% Parse inputs with default settings
% default options
defaultOpt=struct(...
    ...  % new options
    'wantfig', 1, ... % show the figure
    'annot', '',... % do not display annotation
    'annotwidth', {0.5},... % width of the annotation lines
    'annotname', '', ... % cell list of all annot areas to be displayed
    'thresh',[],...
    'clim', [], ...
    'cmap', jet(256), ...
    'fminmax', [2 5], ... 0.01 0.00001
    ...  % options in cvnlookupimages
    'roimask',[],...
    'roiwidth',{.5},...
    'roicolor',{[1 1 1]},... % default white
    'surfsuffix','orig',...
    'rgbnan',0.5,... % the background color (gray)
    'hemiborder',2,...
    'hemibordercolor',0.5,... % set the border as gray
    'imageres', 1000, ...
    'surftype','inflated', ...
    'xyextent', [1 1],...
    'cvnopts', {{}}... % extra options used in cvnlookupimages.m
    );

% parse options
options=fs_mergestruct(defaultOpt, varargin{:});
% Some other general setting
thresh = options.thresh;
clim = options.clim;
cmap = options.cmap;
fminmax = options.fminmax;
surfsuffix = options.surfsuffix;
bgcolor = options.rgbnan;
surftype = options.surftype;
imageres = options.imageres;
xyextent = options.xyextent;
extraopts = options.cvnopts;

if ~exist('viewIdx', 'var') || isempty(viewIdx)
    viewIdx = 3;
end
if ~exist('trgSubj', 'var') || isempty(trgSubj)
    trgSubj = 'fsaverage';
end
hemiInfo = {'numlh', 'numrh'};
if ~exist('valstruct', 'var') || isempty(valstruct)
    % deal with valstruct data
    valstruct = valstruct_create(trgSubj,surfsuffix);
    valstruct.data = randn(size(valstruct.data));
elseif ischar(valstruct) && startsWith(valstruct, 'nodata')
    % do not show any data
    isHemiTemp = strcmp(['num' valstruct(7:end)], hemiInfo);
    % create valstruct data with all zeros
    valstruct = valstruct_create(trgSubj,surfsuffix);
    
    % remove the unwanted hemisphere
    if any(isHemiTemp)
        valstruct.(hemiInfo{~isHemiTemp}) = 0;
        valstruct.data = valstruct.data(1: valstruct.(hemiInfo{isHemiTemp}));
    end
    thresh = 1i;
elseif ~isstruct(valstruct)
    error('Please make sure ''valstruct'' is struct.');
end
if ~exist('extraopts','var') || isempty(extraopts)
    extraopts = {};
end

% deal with viewhemis based on valstruct
isHemi = ismember(hemiInfo, fieldnames(valstruct));
if all(isHemi); isHemi = cellfun(@(x) valstruct.(x)~=0, hemiInfo); end
viewhemis = erase(hemiInfo(isHemi), 'num');

% set color limit if it is empty
if isempty(clim)
    clim = prctile(valstruct.data(:),[1 99]);
end

% set colormap
if ischar(cmap) && strcmp(cmap, 'fsheatscale')
    cmap = fs_heatscale(fminmax(1), fminmax(2));
    thresh = fminmax(1) * 1i;
    clim = [-fminmax(2), fminmax(2)];
end

%% Load the viewponit(s)

if isnumeric(viewIdx) && viewIdx < 0
    % view indices Part 1
    view_number = -viewIdx;
    
    %%%%%%%%%%%%% View information %%%%%%%%%%%%%%%%
    allviewpt = {
        % 1
        {{[270, 0, 0], [90, 0, 0]}; ...  % lateral
        {[90, 0, 0], [270, 0, 0]}; ...   % mdeidal
        {[270, -89, 0], [90, -89, 0]}};  % ventral
        % 2
        {{[90, 0, 0], [270, 0, 0]}; ...  % mdeidal
        {[270, 0, 0], [90, 0, 0]}; ...   % lateral
        {[270, -89, 0], [90, -89, 0]};   % ventral
        {[180, 0, 0], [180, 0, 0]};      % frontal
        {[0, 0, 0], [0, 0, 0]}};         % occipital
        % 3
        {{[180, 0, 0], [180, 0, 0]};     % frontal
        {[0, 0, 0], [0, 0, 0]}};         % occipital
        % 4
        {{[], []}}; % for showing FFA, VWFA, and LO
        };
    
    % views for the hemi
    thisviewpt = cellfun(@(x) x(:, isHemi), allviewpt{view_number, :}, 'uni', false);
    
elseif isnumeric(viewIdx) && viewIdx > 0
    % view indices Part 2
    view_number = viewIdx;
    
    %%%%%%%%%%%%%%%% This part is copied from cvnlookup.m %%%%%%%%%%%%%%%%
    % define some views. inherited from cvnvisualizeanatomicalresults.m:
    allviews = { ...
        {'occip'           'sphere'                   0 1000    0         [1 1]} ...
        {'occip'           'inflated'                 0 1000    0         [1 1]} ...
        {'ventral'         'inflated'                 1 1000    0         [1 1]} ...
        {'parietal'        'inflated'                 0  500    0         [1 1]} ...
        {'medial'          'inflated'                 0  500    0         [1 1]} ...
        {'lateral'         'inflated'                 0  500    0         [1 1]} ...
        {'medial-ventral'  'inflated'                 0  500    0         [1 1]} ...
        {'ventral'         'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
        {''                'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
        {''                'full.flat.patch.3d'       0 1500    1         [290 0]} ...   % 5.17 pixels per mm
        {'ventral-lateral' 'inflated'                 1 1000    0         [1 1]} ...
        {'lateral-auditory' 'inflated'                0 1000    0         [1 1]} ...
        {''                'full.flat.patch.3d'       0 1500    0         []} ...
        {'superior'        'inflated'                 0  500    0         [1 1]} ...
        {'frontal'         'inflated'                 0  500    0         [1 1]} ...
        };
    
    % load view parameters
    if isnumeric(view_number)
        view = allviews{view_number};   % view
        viewname = view{1};             % ventral, occip, etc.
        surftype = view{2};             % inflated, sphere, etc.
        hemiflip = view{3};             % flip hemispheres?
        imageres = view{4};             % resolution
        fsaverage0 = view{5};           % want to map to fsaverage?
        xyextent = view{6};             % xy extent to show
    elseif ischar(view_number)
        viewname = view_number;
        surftype = 'sphere';
        hemiflip = 0;
        imageres = 1000;
        fsaverage0 = 0;
        xyextent = [1 1];
    else
        viewname = view_number{1};
        surftype = view_number{2};
        hemiflip = view_number{3};
        imageres = view_number{4};
        fsaverage0 = view_number{5};
        xyextent = view_number{6};
    end
    if fsaverage0
        assert(isequal(surfsuffix,'orig'),'only orig surface data can be put onto fsaverage');
        surfsuffix = 'fsaverage';     % set to fsaverage non-dense surface
    end
    
    [viewpt, ~, viewhemis] = cvnlookupviewpoint(trgSubj,viewhemis,viewname,surftype);
    
    thisviewpt = {viewpt};
    
elseif ischar(viewIdx)
    % decide the viewpt depends on the viewIdx (string)
    thisviewpt = fs_cvn_viewpt(viewIdx, isHemi);
else
    thisviewpt = {viewIdx};
    viewIdx = 0;
end

if ~exist('lookups','var') || isempty(lookups)
    lookups = repmat({''}, size(thisviewpt, 1), 1);
end

%% Add annotations as roi masks if necessary
% process roi masks
roimasks = options.roimask;
if isnumeric(roimasks) && ~isempty(roimasks); roimasks = {roimasks}; end
nRoi = numel(roimasks);
roicolor = options.roicolor;
roiwidth = options.roiwidth;
% use roicolor and roiwidth for all rois if their numbers do not match
if size(roicolor, 1) ~= nRoi
    roicolor = repmat(roicolor, nRoi, 1);
end
if numel(roiwidth) ~= nRoi
    roiwidth = repmat(roiwidth, nRoi, 1);
end

% load settings for adding annotations as extra masks
annot = options.annot;
annotwidth = options.annotwidth;
annotname = options.annotname;

% make name and load the annotation files
annotFn = cellfun(@(x) sprintf('%s.%s.annot', x, annot), viewhemis, 'uni', false);
[annots, aColor] = cellfun(@(x) fs_readannot(x, trgSubj, annotname), annotFn, 'uni', false);

% combine annotations across hemispheres
annotCom = horzcat(annots{:});
nAnnot = size(annotCom, 1);

% mask cell for annotations
theAnnot = arrayfun(@(x) vertcat(annotCom{x, :}), 1:nAnnot, 'uni', false)';
% annotation colors
aUniColor = vertcat(aColor{:});
aUniColor = aUniColor(1:nAnnot, :);
% annotwidth
if ~iscell(annotwidth); annotwidth = {annotwidth}; end
if numel(annotwidth) ~= nAnnot
    annotwidth = repmat(annotwidth, nAnnot, 1);
end

%% generate image
if isreal(thresh)
    threshopt = {'threshold',thresh};
else
    threshopt = {'absthreshold',imag(thresh)};
end

[rawimg,lookup,rgbimgs] = cellfun(@(x, y) cvnlookupimages(trgSubj,...
    valstruct, viewhemis, x, y,...
    'xyextent',xyextent, ...
    'surftype', surftype,...
    'surfsuffix', surfsuffix,...
    'clim', clim, ...
    'cmap', cmap, ... % this might be covered by later arguments
    'rgbnan', bgcolor, ... %'text',upper(viewhemis),
    'roimask', [roimasks;theAnnot], ...
    'roicolor', [roicolor; aUniColor], ...
    'roiwidth', [roiwidth; annotwidth], ...
    'hemiborder', options.hemiborder,...
    'hemibordercolor', options.hemibordercolor,... % set the border as gray
    'imageres', imageres, ...
    threshopt{:},extraopts{:}), ...
    thisviewpt, lookups, 'uni', false);

% format the rgbimg in images
switch viewIdx
    case {-1, -3}
        rgbimg = img_vertcat(bgcolor, rgbimgs{:});
    case -2
        rgbimg1 = img_vertcat(bgcolor, rgbimgs{1:3});
        rgbimg2 = img_vertcat(bgcolor, rgbimgs{4:5});
        rgbimg = img_horzcat(bgcolor, rgbimg1, rgbimg2);
    otherwise
        rgbimg = rgbimgs{1};
end

% visualize rgbimg
switch options.wantfig
    case 1
        figure; himg = imshow(rgbimg);
    case 2
        figure('Visible','off'); himg = imshow(rgbimg);
    otherwise
        himg = [];
end

% deal with output
if viewIdx > 0; lookup = lookup{1}; end
if nargout == 0
    assignin('base','rawimg',rawimg);
    assignin('base','lookup',lookup);
    assignin('base','rgbimg',rgbimg);
    assignin('base','himg',himg);
else
    varargout{1} = rawimg;
    varargout{2} = lookup;
    varargout{3} = rgbimg;
    varargout{4} = himg;
end

end

%% Combine all the input rgbimg vertically
function rgbimgV = img_vertcat(bgcolor, varargin)

imgCell = varargin;

% find maximum width and the differences between each one
widths = cellfun(@(x) size(x, 2), imgCell);
diff = max(widths) - widths;

% create supplementary array with backgroup colors
if any(diff)
    extra = arrayfun(@(x, y) bgcolor * ones(size(x{1}, 1), y, 3), imgCell, diff, 'uni', false);
    imgCell = cellfun(@horzcat, imgCell, extra, 'uni', false);
end

% combine all rgbimg
rgbimgV = vertcat(imgCell{:});

end

%% Combine all the input rgbimg vertically
function rgbimgH = img_horzcat(bgcolor, varargin)

imgCell = varargin;

% find maximum heights and the differences between each one
heights = cellfun(@(x) size(x, 1), imgCell);
diff = max(heights) - heights;

% create supplementary array with backgroup colors
if any(diff)
    extra = arrayfun(@(x, y) bgcolor * ones(y, size(x{1}, 2), 3), imgCell, diff, 'uni', false);
    imgCells = cellfun(@vertcat, imgCell, extra, 'uni', false);
end

% combine all rgbimg
rgbimgH = horzcat(imgCells{:});

end