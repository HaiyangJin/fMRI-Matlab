function [lookup, rgbimg, himg] = fs_cvn_lookuplmv(subjCode, valstruct,...
    clim0, cmap0, thresh0, lookups, wantfig, extraopts, surfsuffix)
% [fig, lookup, rgbimg, himg] = fs_cvn_lookuplmv(subjCode,valstruct,...
%    clim0, cmap0, thresh0, lookup, wantfig, extraopts, surfsuffix)
%
% This function uses (copies) cvn codes to plot surface data on lateral, 
% medial, and ventral viewpoints at the same time.
%
% Inputs:
%    subjCode         <string> subject code in $SUBJECTS_DIR.
%    valstruct        <struct> struct('data',<L+R x 1>,'numlh',L,'numrh',R) 
%                      to create images for both hemispheres side by side.  
%                      In this case, hemi, view_az_el_tilt, and Lookup must 
%                      be cell arrays.
%    clim0            <numeric> colormap limits. e.g., [-2, 2].
%    cmap0            <string> colormap for input image (default = jet).
%    thresh0          <numeric> display threshold. overlayalpha =
%                      ,val>threshold. Only show activation within the
%                      threshold.
%    lookups          <struct> the Lookup to re-use.
%    wantfig          <logical/integer> whether to show a figure. 1: show  
%                      figure (default); 2: do not show figure, but output 
%                      himg. 
%    extraopts        <cell> a cell vector of extra options to 
%                      cvnlookupimages.m. Default: {}.
%    surfsuffix       <string>  'orig' or 'DENSETRUNCpt'. Default is 'orig' 
%                      which means standard non-dense FreeSurfer surfaces.
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
% Dependency:
%    cvn codes: https://github.com/kendrickkay/knkutils.git
%               https://github.com/kendrickkay/cvncode.git
%
% Created by Haiyang Jin (13-Apr-2020)

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
end
if ~exist('cmap0','var') || isempty(cmap0)
    cmap0 = jet(256);
end
if ~exist('thresh0','var') || isempty(thresh0)
    thresh0 = [];
end
if ~exist('lookup', 'var') || isempty(lookups)
    lookups = {''; ''; ''};
end
if ~exist('wantfig','var') || isempty(wantfig)
    wantfig = 1;
end
if ~exist('extraopts','var') || isempty(extraopts)
    extraopts = {};
end
if ~exist('surfsuffix','var') || isempty(surfsuffix)
    surfsuffix = 'orig';  % default is standard non-dense surfaces
end

if ~exist('valstruct', 'var') || isempty(valstruct)
    % deal with valstruct data
    valstruct = valstruct_create(subjCode,surfsuffix);
    valstruct.data = randn(size(valstruct.data));
elseif ~isstruct(valstruct)
    error('Please make sure ''valstruct'' is struct.'); 
end
% deal with color range
if ~exist('clim0', 'var') || isempty(clim0)
    clim0 = prctile(valstruct.data(:),[1 99]);
end

% deal with viewhemis based on valstruct
hemis = {'lh', 'rh'};
isHemi = ismember({'numlh', 'numrh'}, fieldnames(valstruct));
viewhemis = hemis(isHemi);

%% Some other general setting
if isreal(thresh0)
    threshopt = {'threshold',thresh0};
else
    threshopt = {'absthreshold',imag(thresh0)};
end
surftype = 'inflated';
imageres = 1000;

% viewpoints
viewpt = {
    {[270, 0, 0], [90, 0, 0]};  % lateral
    {[90, 0, 0], [270, 0, 0]};  % mdeidal
    {[270, -89, 0], [90, -89, 0]} % ventral
    };

%% generate image
[~,lookup,rgbimgs] = cellfun(@(x, y) cvnlookupimages(subjCode,...
    valstruct, viewhemis, x, y,...
    'surftype',surftype,'surfsuffix',surfsuffix,...
    'imageres',imageres,'rgbnan',0.5, ... %'text',upper(viewhemis),
    'clim',clim0,'colormap',cmap0,threshopt{:},extraopts{:}), ...
    viewpt, lookups, 'uni', false);

% combine the three images
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