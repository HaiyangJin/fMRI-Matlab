function [lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj, view, valstruct, ...
    thresh0, lookups, wantfig, extraopts)
% [fig, lookup, rgbimg, himg] = fs_cvn_lookup(trgSubj,view,valstruct,...
%    thresh0, lookup, wantfig, extraopts)
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
%    thresh0          <numeric> display threshold. overlayalpha =
%                      ,val>threshold. Only show activation within the
%                      threshold.
%    lookups          <struct> the Lookup to re-use.
%    wantfig          <logical/integer> whether to show a figure. 1: show  
%                      figure (default); 2: do not show figure, but output 
%                      himg. 
%    extraopts        <cell> a cell vector of extra options to 
%                      cvnlookupimages.m. Default: {}.
%
% Output:
%    fig:             <figure hanlde> for saving the image as pdf.
%    Lookup:          <struct> Structure containing lookup information.  
%                      Can speed up multiple lookups with the same viewpoint.
%                  OR <cell array> if two hemis provided in input.
%    rgbimg:          <numeric array> output containing RGB image:
%                      <res>x<res>x3.
%    himg             <image handle>
%
%
% Views:
%    1  vertical layout(one column): lateral, medial, ventrcal;
%    2     
%
% Dependency:
%    cvn codes: https://github.com/kendrickkay/knkutils.git
%               https://github.com/kendrickkay/cvncode.git
%
% Created by Haiyang Jin (13-Apr-2020)

% View information
viewStr = {'lmv'};
viewpt = {
    % 1
    {{[270, 0, 0], [90, 0, 0]}; ...  % lateral
    {[90, 0, 0], [270, 0, 0]}; ...  % mdeidal
    {[270, -89, 0], [90, -89, 0]}}; % ventral
    %2
    {{[0, 0, 0], [0, 0, 0]}}
    };

surfsuffix = 'orig';  % default is standard non-dense surfaces
if ~exist('view', 'var') || isempty(view)
    view = 1;
elseif ischar(view)
    view = find(strcmp(view, viewStr));
end
if ~exist('valstruct', 'var') || isempty(valstruct)
    % deal with valstruct data
    valstruct = valstruct_create(trgSubj,surfsuffix);
    valstruct.data = randn(size(valstruct.data));
elseif ~isstruct(valstruct)
    error('Please make sure ''valstruct'' is struct.'); 
end
if ~exist('trgSubj', 'var') || isempty(trgSubj)
    trgSubj = 'fsaverage';
end
if ~exist('thresh0','var') || isempty(thresh0)
    thresh0 = 1.3010i;
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
imageres = 1000;

%% generate image
[~,lookup,rgbimgs] = cellfun(@(x, y) cvnlookupimages(trgSubj,...
    surfdata, viewhemis, x, y,...
    'surftype',surftype,'surfsuffix',surfsuffix,...
    'imageres',imageres,'rgbnan',0.5, ... %'text',upper(viewhemis),
    threshopt{:},extraopts{:}), ...
    thisviewpt, lookups, 'uni', false);

% combine the three images
widths = cellfun(@(x) size(x, 2), rgbimgs);
diff = max(widths) - widths;
if any(diff)
    extra = arrayfun(@(x, y) 0.5 * ones(size(x{1}, 1), y, 3), rgbimgs, diff, 'uni', false);
    rgbimgs = cellfun(@horzcat, rgbimgs, extra, 'uni', false);
end

rgbimg = vertcat(rgbimgs{:});

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