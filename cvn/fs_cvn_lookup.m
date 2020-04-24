function varargout= fs_cvn_lookup(trgSubj,viewIdx,valstruct,lookups,varargin)
% [rawimg, lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj,view,valstruct,...
%    [lookups, varargin])
%
% This function uses (copies) cvn codes to plot surface data on lateral,
% medial, and ventral viewpoints at the same time.
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
%                      'nodatarh' only displays right hemisphere.]
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
%                      e.g. 'fusiform' for 'aparc' (in 'annot').
%    'thresh0'        <numeric> real number for numbers with sign and
%                      non-real number is treated as abosolute threshold.
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
% Views:
%    1  vertical layout (one column): lateral, medial, ventrcal;
%    2  two columns: first: lateral, medial, ventrcal;
%                    second: frontal, occipital;
%    3  vertical layout (one column): frontal, occipital;
%
%
% % Example 1: show random activations on both hemispheres with view 1
% fs_cvn_lookup('fsaverage', 1);
%
% % Example 2: show random activations on left hemisphere with view 1
% valstruct.numlh = 163842;
% valstruct.data = randn(valstruct.numlh,1);
% fs_cvn_lookup('fsaverage', 1, valstruct);
%
% % Example 3: show brain only (no data)
% fs_cvn_lookup('fsaverage', 1, 'nodata');
%
% % Example 4: show annotations without data
% fs_cvn_lookup('fsaverage', 1, 'nodata', [], '', 'annot', 'aparc');
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
    'annotwidth', 0.5,... % width of the annotation lines
    'annotname', '', ... % cell list of all annot areas to be displayed
    'thresh0',[],...
    'clim0', [], ...
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
thresh0 = options.thresh0;
surfsuffix = options.surfsuffix;
bgcolor = options.rgbnan;
surftype = options.surftype;

%%%%%%%%%%%%% View information %%%%%%%%%%%%%%%%
viewStr = {'lmv', 'lmvfo', 'fo'};
viewpt = {
    % 1
    {{[270, 0, 0], [90, 0, 0]}; ...  % lateral
    {[90, 0, 0], [270, 0, 0]}; ...   % mdeidal
    {[270, -89, 0], [90, -89, 0]}};  % ventral
    % 2
    {{[270, 0, 0], [90, 0, 0]}; ...  % lateral
    {[90, 0, 0], [270, 0, 0]}; ...   % mdeidal
    {[270, -89, 0], [90, -89, 0]};   % ventral
    {[180, 0, 0], [180, 0, 0]};      % frontal
    {[0, 0, 0], [0, 0, 0]}}          % occipital
    % 3
    {{[180, 0, 0], [180, 0, 0]};     % frontal
    {[0, 0, 0], [0, 0, 0]}}          % occipital
    };

if ~exist('view', 'var') || isempty(view)
    view = 1;
elseif ischar(view)
    view = find(strcmp(view, viewStr));
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
    isNoHemi = strcmp(['num' valstruct(7:end)], hemiInfo);
    % create valstruct data with all zeros
    valstruct = valstruct_create(trgSubj,surfsuffix);
    %     valstruct = rmfield(valstruct, hemiInfo(isNoHemi));
    if any(isNoHemi)
        valstruct.(hemiInfo{isNoHemi}) = 0;
        valstruct.data = valstruct.data(1: sum(valstruct.(hemiInfo{~isNoHemi})));
    end
    thresh0 = 1i;
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

% views for the hemi
thisviewpt = cellfun(@(x) x(:, isHemi), viewpt{view, :}, 'uni', false);

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
if numel(roicolor) ~= nRoi
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
if numel(annotwidth) ~= nAnnot
    annotwidth = repmat(annotwidth, nAnnot, 1);
end

%% Load the viewponits
% hemi
if numel(viewhemis) == 1
    thisviewpt = cellfun(@(x) x{1}, thisviewpt, 'uni', false);
end

% [viewpt, viewhemis, viewhemi] = cvnlookupviewpoint(trgSubj,viewhemis,viewname,surftype);

%% generate image
if isreal(thresh0)
    threshopt = {'threshold',thresh0};
else
    threshopt = {'absthreshold',imag(thresh0)};
end

[rawimg,lookup,rgbimgs] = cellfun(@(x, y) cvnlookupimages(trgSubj,...
    valstruct, viewhemis, x, y,...
    'surftype', surftype,...
    'surfsuffix', surfsuffix,...
    'rgbnan', bgcolor, ... %'text',upper(viewhemis),
    'roimask', [roimasks;theAnnot], ...
    'roicolor', [roicolor; aUniColor], ...
    'roiwidth', [roiwidth; annotwidth], ...
    'hemiborder', options.hemiborder,...
    'hemibordercolor', options.hemibordercolor,... % set the border as gray
    'imageres', options.imageres, ...
    threshopt{:},extraopts{:}), ...
    thisviewpt, lookups, 'uni', false);

% format the rgbimg in images
switch view
    case {1, 3}
        rgbimg = img_vertcat(bgcolor, rgbimgs{:});
    case 2
        rgbimg1 = img_vertcat(bgcolor, rgbimgs{1:3});
        rgbimg2 = img_vertcat(bgcolor, rgbimgs{4:5});
        rgbimg = img_horzcat(bgcolor, rgbimg1, rgbimg2);
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
if nargout == 0
    assignin('base','rawimg',rawimg);
    assignin('base','Lookup',lookup);
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