function rdm_plotrdm(rdms, varargin)
% rdm_plotrdm(rdms, varargin)
%
% Quickly show the RDM (matrix).
%
% Inputs:
%     rdms    <num mat> RDM matrix (not vectors). 
%     
% Varargin:
%     .condnames     <str cell> strings to be displayed for conditions.
%     .titles        <str cell> titles to be displayed for each RDM.
%     .nrow          <int> number of rows to be displayed in subplot().
%     .eachsize      <int vec> pixels of x and y dimension for plotting  
%                     each RDM. If the length of {eachsize} is 1, it will
%                     be used for both x and y.
%     .position      <int vec> the position of the figure.
%     .cmap          <str> or <mat> colormap to be used.
%     .crange        <num vec> range to be displayed in colorbar.
%     .showbar       <boo> whether show color bar.
%
% Created by Haiyang Jin (2022-Aug-19)

if nargin < 1
    fprintf('Usage: rdm_plotrdm(rdms, varargin):\n');
end

defaultOpts = struct( ...
    'condnames', '', ... % conditions names to show in matrix
    'titles', '', ... % for each (sub)plot
    'nrow', 1, ... % N row used in subplot()
    'eachsize', 400, ... % pixels (x and y) for each 
    'position', [], ...
    'cmap', 'jet', ...
    'crange', [], ...
    'showbar', 1 ... % whether show colorbar
    );

opts = fm_mergestruct(defaultOpts, varargin);

% make sure rdms is RDM matrix
assert(size(rdms,1)==size(rdms,2), ['{rdms} must be RDM matrix, ' ...
    'not RDM vectors. [You may want to use rdm_vec2rdm().]']);

N_cond = size(rdms, 1);
N_rdms = size(rdms, 3);

% condition names
if isempty(opts.condnames)
    condnames = arrayfun(@(x) sprintf('cond%d',x), 1:N_cond, 'uni', false);
else
    condnames = opts.condnames;
end

% (sub)plot titles
if isempty(opts.titles)
    titles = arrayfun(@(x) sprintf('RDM %d',x), 1:N_rdms, 'uni', false);
else
    titles = opts.titles;
end

% ncol for subplot
if N_rdms > 1
    ncol = ceil((N_rdms+1) / opts.nrow);
else
    ncol = 1;
end

% figure position
if length(opts.eachsize)==1
    opts.eachsize = [opts.eachsize, opts.eachsize];
end
if isempty(opts.position)
    opts.position = 100+[0 0 opts.eachsize(2)*ncol opts.eachsize(1)*opts.nrow];
end


%% Plot RDM
figure('DefaultAxesFontSize',14);
set(gcf,'Position', opts.position);

colormap(opts.cmap)


% plot each RDM separately
for i = 1:N_rdms

    % use subplot if needed
    subplot(opts.nrow, ncol, i);
    
    % plot the matrix
    imagesc(rdms(:,:,i));
    % add title
    title(titles{i}, 'FontSize', 24, 'FontWeight', 'Normal')
    if ~isempty(opts.crange); caxis(opts.crange); end

    % add row and col names
    ax = gca;
    % Set where ticks will be 
    yticks(1:N_cond);
    xticks(1:N_cond);
    % set TickLabels
    ax.XTickLabel = condnames;
    ax.XTickLabelRotation = 90;
    ax.YTickLabel = condnames;

end

if opts.showbar
    if N_rdms > 1
        subplot(opts.nrow, ncol, N_rdms+1); 
    end
    c = colorbar;
    if ~isempty(opts.crange) 
        caxis(opts.crange); 
    else
        c.Ticks = [0, 1];
        c.TickLabels = {'low', 'high'};
    end
    colormap;
    c.FontSize = 15;
    axis off
    
end

end
