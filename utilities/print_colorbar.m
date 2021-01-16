function print_colorbar(clim, ctricks, csize, cmap, fn)
% print_colorbar(clim, ctricks, csize, cmap, fn)
%
% Inputs:
%    clim      <numeric> 1x2 vector. The minimum and maximum limits for the
%               colorbar.
%    ctricks   <numeric vector> tricks to be displayed on the colorbar.
%    cmap      <string or colormap array> use which color map,
%               default is jet(256).
%    csize     <numeric vector> 1x4 vector. csize will be used as the
%               position of the colorbar.
%    fn        <string> filename of the output colorbar. Default is
%               'colorbar.pdf'.
%
% Output:
%    the output colorbar image.
%
% Created by Haiyang Jin (15-Jan-2021)

if ~exist('clim', 'var') || isempty(clim)
    clim = [0 1];
end
if ~exist('ctricks', 'var') || isempty(ctricks)
    ctricks = [0 0.5 1];
end
if ~exist('csize', 'var') || isempty(csize)
    csize = [0.5 0.1 0.05 0.7];
end
if ~exist('cmap', 'var') || isempty(cmap)
    cmap = jet(256);
end
if ~exist('fn', 'var') || isempty(fn)
    fn = 'colorbar.pdf';
end

f = figure('Visible', 'off');

c = colorbar;

caxis(clim);

colormap(cmap);

c.Ticks = ctricks;
c.FontSize = 15;

c.Position = csize;

axis off

% c.Label.FontSize = 20;+

print(gcf,fn,'-dpdf','-r300');

% png_trans('colorbar.png');

close(f);

end