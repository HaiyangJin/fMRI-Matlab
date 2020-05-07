function cmap = fs_heatscale(fmin, fmax, varargin)
% cmap = fs_heatscale(fmin, fmax, varargin)
%
% This function tries to create a colormap which is similar to the
% heatscale in FreeSurfer. (Hopefully they are the same... not sure).
%
% Inputs:
%    fmin          <numeric> minimum value for the threshold (the 'min' in
%                   '-fminmax' in FreeSurfer. Default is 2.
%    fmax          <numeric> maximum value for the threshold (the 'max' in
%                   '-fminmax' in FreeSurfer. Default is 10.
%
% Optional:
%    'flipwc'      <logical> whether flip the cold colors to the top.
%                   Default is 0.
%    'bgcolor'     <numeric> the RGB for the background color. Default is
%                   [0.5 0.5 0.5];
%    'savecbar'    <logical> save the cmap as an image. Default is 0.
%    'bgtrans'     <logical> if the "gray" part saved as transparent.
%                   Default is 0.
%    'barwidth'    <integer> the width of the "colorbar" saved in the
%                   image.
%    'ntrick'      <integer> number of tricks to be shown for the
%                   "colorbar". Default is 3.
%
% Output:
%    cmap       <numeric array> 256x3 color map array.
%
% Created by Haiyang Jin (7-May-2020)

%% Deal with inputs
if ~exist('fmin', 'var') || isempty(fmin)
    fmin = 2;
end
if ~exist('fmax', 'var') || isempty(fmax)
    fmax = 10;
end

defaultOpts = {...
    'flipwc', 0, ...
    'bgcolor', [0.5 0.5 0.5], ...
    'savecbar', 0, ...
    'bgtrans', 0, ...
    'barwidth', 50, ...
    'ntrick', 3, ...
    'warmmin', [176 38 13]/255,...
    'warmmax', [255 255 48]/255,...
    'coldmin', [1 0 192]/255, ...
    'coldmax', [117 251 254]/255, ...
    };

options = fs_mergestruct(defaultOpts, varargin);

flipwc = options.flipwc;
bgColor = options.bgcolor;
saveCbar = options.savecbar;
bgTrans = options.bgtrans;
barWidth = options.barwidth;
nTrick = options.ntrick;
warmMinColor = options.warmmin;
warmMaxColor = options.warmmax;
coldMinColor = options.coldmin;
coldMaxColor = options.coldmax;

if numel(bgColor) == 1
    bgColor = repmat(bgColor, 1, 3);
end

%% Create the colormap matrix
% number of columns for each part
nRange = ceil((fmax-fmin)/fmax * 128);
nChange = ceil(nRange/2);
nFix = nRange-nChange;

% color parts
linWarm = arrayfun(@(x) linspace(warmMaxColor(:, x), warmMinColor(:, x), nChange)', 1:3, 'uni', false);
linWarm = horzcat(linWarm{:});
linWarmFix = repmat(warmMinColor, nFix, 1);
linColdFix = repmat(coldMinColor, nFix, 1);
linCold = arrayfun(@(x) linspace(coldMinColor(:, x), coldMaxColor(:, x), nChange)', 1:3, 'uni', false);
linCold = horzcat(linCold{:});

% background parts
nBg = 256 - 2* nRange;
linGray = repmat(bgColor, nBg, 1);

% create the colormap matrix
cmap = vertcat(linWarm, linWarmFix, linGray, linColdFix, linCold);

% flip the warm and cold if needed
if ~flipwc
    cmap = flipud(cmap);
end

%% Create and save the color bar (if need)
if saveCbar
    
    % convert the colorbar matrix to image matrix
    cbar = reshape(flipud(cmap), [256, 1, 3]);
    cbars = repmat(cbar, 1, barWidth);
    
    % show the "colorbar"
    figure('Visible', 'off');
    h = imshow(cbars);
    
    % make the middle gray part as transparent
    if bgTrans
        alphaM = ones(256, 1);
        alphaM(nRange+(1:nBg))= 0;
        calpha = repmat(alphaM, 1, barWidth);
        
        set(h, 'AlphaData', calpha);
    end
    
    % add the labels
    cWarmValue = linspace(fmax, fmin, nTrick);
    cStringCell = arrayfun(@num2str, [cWarmValue, -fliplr(cWarmValue)], 'uni', false);
    
    cWarmY = linspace(1, nRange, nTrick);
    cColdY = linspace(nBg+nRange, 256, nTrick);
    
    cX = repmat(barWidth * 1.1, 1, numel(cStringCell));
    
    text(cX, [cWarmY cColdY], cStringCell, 'FontSize',20);
    
end

end