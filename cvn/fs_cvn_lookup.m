function [lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj, view, valstruct, ...
    thresh0, lookups, wantfig, extraopts)
% [lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj,view,valstruct,...
%    thresh0, lookups, wantfig, extraopts)
%
% This function uses (copies) cvn codes to plot surface data on lateral,
% medial, and ventral viewpoints at the same time.
%
% Inputs:
%    trgSubj          <string> whose coordiantes will be used for plotting.
%    view             <integer> which views are used to display the
%                      results. More see below.
%    valstruct        <struct> struct('data',<L+R x 1>,'numlh',L,'numrh',R)
%                      to create images for both hemispheres side by side.
%                      In this case, hemi, view_az_el_tilt, and Lookup must
%                      be cell arrays.
%    thresh0          <numeric> display threshold. Default is [] which
%                      means no thresholding.
%    lookups          <struct> the Lookup to re-use.
%    wantfig          <logical/integer> whether to show a figure. 1: show
%                      figure (default); 2: do not show figure, but output
%                      himg.
%    extraopts        <cell> a cell vector of extra options to
%                      cvnlookupimages.m. Default: {}.
%
% Output:
%    lookup:          <struct> Structure containing lookup information.
%                      Can speed up multiple lookups with the same viewpoint.
%                  OR <cell array> if two hemis provided in input.
%    rgbimg:          <numeric array> output containing RGB image:
%                      <res>x<res>x3.
%    himg             <image handle>
%
%
% Views:
%    1  vertical layout (one column): lateral, medial, ventrcal;
%    2  two columns: first: lateral, medial, ventrcal; 
%                    second: frontal, occipital;
%    3  vertical layout (one column): frontal, occipital;
%
% Example: show random activations on fsaverage with view 1
% fs_cvn_lookup('fsaverage', 1);
%
% Dependency:
%    cvn codes: https://github.com/kendrickkay/knkutils.git
%               https://github.com/kendrickkay/cvncode.git
%
% Created by Haiyang Jin (13-Apr-2020)

% View information
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

surfsuffix = 'orig';  % default is standard non-dense surfaces
if ~exist('view', 'var') || isempty(view)
    view = 1;
elseif ischar(view)
    view = find(strcmp(view, viewStr));
end
if ~exist('trgSubj', 'var') || isempty(trgSubj)
    trgSubj = 'fsaverage';
end
if ~exist('valstruct', 'var') || isempty(valstruct)
    % deal with valstruct data
    valstruct = valstruct_create(trgSubj,surfsuffix);
    valstruct.data = randn(size(valstruct.data));
elseif ~isstruct(valstruct)
    error('Please make sure ''valstruct'' is struct.');
end
if ~exist('thresh0','var') || isempty(thresh0)
    thresh0 = 0.0001i;
end
if ~exist('wantfig','var') || isempty(wantfig)
    wantfig = 1;
end
if ~exist('extraopts','var') || isempty(extraopts)
    extraopts = {};
end

% deal with viewhemis based on valstruct
hemis = {'lh', 'rh'};
isHemi = cellfun(@(x) valstruct.(x)~=0, {'numlh', 'numrh'});
viewhemis = hemis(isHemi);

% views for the hemi
thisviewpt = cellfun(@(x) x(:, isHemi), viewpt{view, :}, 'uni', false);

if ~exist('lookups','var') || isempty(lookups)
    lookups = repmat({''}, size(thisviewpt, 1), 1);
end

if numel(viewhemis) == 1
    surfdata = valstruct.data;
    viewhemis = viewhemis{1};
    thisviewpt = cellfun(@(x) x{1}, thisviewpt, 'uni', false);
else
    surfdata = valstruct;
end

%% Some other general setting
if isreal(thresh0)
    threshopt = {'threshold',thresh0};
else
    threshopt = {'absthreshold',imag(thresh0)};
end
surftype = 'inflated';
imageres = 1000;  % image resolution
bgcolor = 0.5;  % background color: gray

%% generate image
[~,lookup,rgbimgs] = cellfun(@(x, y) cvnlookupimages(trgSubj,...
    surfdata, viewhemis, x, y,...
    'surftype',surftype,'surfsuffix',surfsuffix,...
    'imageres',imageres,'rgbnan',bgcolor, ... %'text',upper(viewhemis),
    threshopt{:},extraopts{:}), ...
    thisviewpt, lookups, 'uni', false);

% remove the black lines
rgbimgs = cellfun(@(x) img_noline(x, bgcolor), rgbimgs, 'uni', false);

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
switch wantfig
    case 1
        figure; himg = imshow(rgbimg);
    case 2
        figure('Visible','off'); himg = imshow(rgbimg);
    otherwise
        himg = [];
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

%% Remove the black lines in rgbimg
function rgbimgNL = img_noline(rgbimgIn, bgcolor)

% use the first layer to decide which of the columns are the black lines
isLine = rgbimgIn(:, :, 1) == 0;
lineIndex = all(isLine, 1);

% use background color to fill the black lines
rgbimgNL = rgbimgIn;
rgbimgNL(:, lineIndex, :) = bgcolor;

end