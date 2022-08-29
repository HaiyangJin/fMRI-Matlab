function fig = rsa_plotrdm(rdms, varargin)
% fig = rsa_plotrdm(rdms, varargin)
%
% Quickly show the RDM (matrix).
%
% Inputs:
%     rdms    <num mat> RDM matrix (not vectors). 
%     
% Varargin:
%     .condnames     <str cell> strings to be displayed for conditions.
%     .showvalue     <boo> whether show values in the matrix. Default to 0.
%     .titles        <str cell> titles to be displayed for each RDM.
%     .nrow          <int> number of rows to be displayed in subplot().
%     .eachsize      <int vec> pixels of x and y dimension for plotting  
%                     each RDM. If the length of {eachsize} is 1, it will
%                     be used for both x and y.
%     .position      <int vec> the position of the figure.
%     .cmap          <str> or <mat> colormap to be used.
%     .crange        <num vec> range to be displayed in colorbar.
%     .showbar       <boo> whether show color bar.
%     .clabel        <str> the color bar label. Default to 'Dissimilarity'.
%
% Output:
%     fig            figure handle.
%
% Created by Haiyang Jin (2022-Aug-19)

if nargin < 1
    fprintf('Usage: fig = rsa_plotrdm(rdms, varargin):\n');
    return
end

defaultOpts = struct( ...
    'condnames', '', ... % conditions names to show in matrix
    'showvalue', 0, ... % whether show values in the figure
    'titles', '', ... % for each (sub)plot
    'nrow', 1, ... % N row used in subplot()
    'eachsize', 400, ... % pixels (x and y) for each 
    'position', [], ...
    'cmap', 'jet', ...
    'crange', [], ...
    'showbar', 1, ... % whether show colorbar
    'clabel', 'Dissimilarity' ...
    );

opts = fm_mergestruct(defaultOpts, varargin);

% make sure rdms is RDM matrix
assert(size(rdms,1)==size(rdms,2), ['{rdms} must be RDM matrix, ' ...
    'not RDM vectors. [You may want to use rsa_vec2rdm().]']);

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
fig = figure('DefaultAxesFontSize',14);
set(gcf,'Position', opts.position);

colormap(opts.cmap)


% plot each RDM separately
for i = 1:N_rdms

    % use subplot if needed
    subplot(opts.nrow, ncol, i);
    
    % plot the matrix
    imagesc(rdms(:,:,i)); % maybe try heatmap()
    % add title
    title(titles{i}, 'FontSize', 24, 'FontWeight', 'Normal')
    if ~isempty(opts.crange); caxis(opts.crange); end

    % show values if needed
    if opts.showvalue
        tmpvalues = rdms(:,:,i);
        vals = tmpvalues(:);

        [R, C] = ndgrid(1:size(tmpvalues,1), 1:size(tmpvalues,2));
        R = R(:); C = C(:) - 1/4;

        text(C, R, string(vals), 'color', 'w', 'FontSize', 14);

%         mask = vals <= 0.5;
%         text(C(mask), R(mask), string(vals(mask)), 'color', 'w')
%         text(C(~mask), R(~mask), string(vals(~mask)), 'color', 'k')

    end% opts.showvalue

    % add row and col names
    ax = gca;
    % Set where ticks will be 
    yticks(1:N_cond);
    xticks(1:N_cond);
    % set TickLabels
    ax.XTickLabel = condnames;
    ax.XTickLabelRotation = 90;
    ax.YTickLabel = condnames;

end %for i 

if opts.showbar
    if N_rdms > 1
        subplot(opts.nrow, ncol, N_rdms+1); 
        axis off
    end
    c = colorbar;
    if ~isempty(opts.crange) 
        caxis(opts.crange); 
    else
        c.Ticks = [0, 1];
        c.TickLabels = {'low', 'high'};
    end
    c.Label.String = opts.clabel;
    c.FontSize = 18;
    
end

end
