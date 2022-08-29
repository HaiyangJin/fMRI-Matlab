function rsa_plot(cor, cor_se, N_subj, noiseceiling, varargin)
% rsa_plot(cor, cor_se, N_subj, noiseceiling, varargin)
% 
% Plot for one brain (reference) RDM with multiple model (candidate) RDMs.
%
% Inputs:
%    cor           <vec> Relatedness between one reference RDM and multiple
%                   candidate RDMs.
%    cor_se        <vec> the standard errors of {cor}.
%    N_subj        <int> number of participants.
%    noiseceiling  <vec> the upper and lower boundaries of noise ceiling.
%    
% Varargin:
%    'pone_vec'    <vec> the p-value of one-sided test for each candidate 
%                   model (a vector).
%    'ptwo_mat'    <mat> pairwise comparisons between relatedness for each
%                   pair. It is a matrix and the orders of conditions in x
%                   and y should match that in cor (cor_se, etc.)
%    
%    'sortx'       <boo> whether sort the orders of columns (bars) based on
%                   the {cor}. Default to 1.
%    'modelnames'  <cell str> a list of model names to be displayed.
%                   Default to 'model1', 'model2', etc. 
%    'thresh'      <num> the threshold to be used for claiming significant
%                   results. Default to .05.
%    'correction'  <str> method to be used for multiple comparison
%                   corrections. Default to 'FDR' (others are 'FWE' 
%                   (Bonferroni) or 'none').
%    'fig_handel'  <int> the figure handle of the figure to be plot on.
%                   Default to 0.
%    'subplot'     <int vec> [m,n,p] used in subplot(). Default to [].
%    'subposi'     <num vec> the position of the subplot.
%    'title'       <str> the figure title.
%    'barfacecolor'<str> the color of bars. 
%
% Created by Haiyang Jin (2022-Aug-29)

if nargin < 1
    fprintf('Usage: rsa_plot(cor, cor_se, N_subj, noiseceiling, varargin);\n');
    return
end

%% Deal with inputs
defaultOpts = struct( ...
    'pone_vec', [], ...
    'ptwo_mat', [], ...
    'sortx', 1, ...
    'modelnames', '', ...
    'thresh', 0.05, ...
    'correction', 'FDR', ...
    'fig_handle', [], ...
    'subplot', [], ...
    'subposi', [], ...
    'title', '', ...
    'barfacecolor', '#56B4E9' ... % blue
    );
opts = fm_mergestruct(defaultOpts, varargin);

% apply default model names if needed
if isempty(opts.modelnames)
    modelnames = sprintf('model %d', 1:length(cor), 'uni', false);
else
    assert(length(opts.modelnames)==length(cor), ['The length of ' ...
        '{.modelnames} does not match that of {cor}.']);
    modelnames = opts.modelnames;
end

% sorted by model RDM relatedness if needed
y = cor;
N_model = length(y);
sortedIs = 1:N_model;
if opts.sortx
    [y,sortedIs]=sort(y,'descend');
end

% update order for others
se = cor_se(sortedIs);
modelnames = modelnames(sortedIs);

% prepare for axises
% y-axis limits
if min(y)<0
    Ymin=min(y)-max(se)-.05;
else
    Ymin=0;
end


%% Start to plot
if ~isempty(opts.subplot) && ~isempty(opts.fig_handle)
    set(0,'CurrentFigure', opts.fig_handle);

    if ~isempty(opts.subposi)
        % adjust the area to show figure
        subplot('Position', opts.subposi);
    else
        subplot(opts.subplot(1), opts.subplot(2), opts.subplot(3));
    end
else
    figure;
    % adjust the area to show figure
    set(gca, 'OuterPosition', [0,0.2,1,0.8]);
end

%% Bar plot
bar(y, 'FaceColor', opts.barfacecolor, 'EdgeColor','none', 'ShowBaseLine', 'off');
hold on;
% add error bars
errorbar(y, se, 'Color',[0 0 0],'LineWidth', 2,'LineStyle','none');

% % y-axis label
% ylabel({'\bf RDM correlation', ...
%     sprintf('\\rm [Kendall \\tau_a, averaged across %d subjects]', N_subj)});
% hold on;

%% Display noise ceiling
% get lower and upper boundaries of noise ceiling
noiseceiling = sort(noiseceiling);
lb = noiseceiling(1);
ub = noiseceiling(2);

% patch([min(xlim), min(xlim), max(xlim), max(xlim)], ...
%     [lb(i), ub(i), ub(i), lb(i)], ...
%     [.8,.8,.8], 'EdgeColor','none', 'FaceAlpha',.3)
patch([.1, .1, N_model+1, N_model+1], ...
    [lb, ub, ub, lb], ...
    [.8,.8,.8], 'EdgeColor','none', 'FaceAlpha',.3)

%% label the bars with the names of the candidate RDMs and add the p-values
if ~isempty(opts.pone_vec)
    % add p-value label
    text(.5,Ymin-.05,'\fontsize{10}\rmp = ','Rotation', 0, ...
        'Color', [0 0 0],'HorizontalAlignment','center')
end

for imodel = 1:N_model
    if ~isempty(opts.pone_vec)
        text(imodel, Ymin-.05, sprintf('%0.4f', opts.pone_vec(sortedIs(imodel))), ...
            'HorizontalAlignment','center');
        extray = .07;
    else
        extray = -.02;
    end

    text(imodel, Ymin-0.05-extray, ['\bf', modelnames{imodel}], ...
        'Rotation', 45, 'Color', [0 0 0],'HorizontalAlignment','right');
end

%% Pairwise comparisons between models
if ~isempty(opts.ptwo_mat)
    % sorted if needed
    p_two_mat = opts.ptwo_mat(sortedIs, sortedIs);

    % apply multiple comparison corrections
    P_two_tmp = p_two_mat;
    P_two_tmp(logical(eye(size(p_two_mat,1))))=0;
    p_two_vec = squareform(P_two_tmp);

    switch opts.correction
        case 'FDR'
            threshold = rsa.stat.FDRthreshold(p_two_vec, opts.thresh);
        case 'FWE'
            threshold = opts.thresh/length(p_two_vec);
        case 'none'
            threshold = opts.thresh;
    end

    % show comparison lines
    if N_subj == 1
        yy=rsa.fig.addComparisonBars(p_two_mat,(max(y)+0.1),threshold);
    else
        yy=rsa.fig.addComparisonBars(p_two_mat,(ub+0.1),threshold);
    end

end

%% Use custom axis
% update y-axis
cYLim = get(gca, 'YLim');
cYMax = cYLim(2);
labelBase = cYMax + 0.1;
nYMax = labelBase;
nYLim = [Ymin, nYMax];
set(gca, 'YLim', nYLim);
hold on;

minYTickI=floor(min(y)*10);
maxYTickI=ceil(max([y' ub])*10);

axis off;

% plot pretty vertical axis
lw=1;
for YTickI=minYTickI:maxYTickI
    plot([0.05 0.1],[YTickI YTickI]./10,'k','LineWidth',lw);
    text(0,double(YTickI/10),num2str(YTickI/10,1),'HorizontalAlignment','right');
end
plot([0.1 0.1],[minYTickI YTickI]./10,'k','LineWidth',lw);
text(-1,double((maxYTickI+minYTickI)/10/2),{'\bf RDM correlation', ...
    sprintf('\\rm [Kendall \\tau_a, averaged across %d subjects]', N_subj)}, ...
    'HorizontalAlignment','center','Rotation',90);

if ~exist('yy','var')
    ylim([Ymin max(ub)+0.25]);
else
    ylim([Ymin yy+.1]);
end

% add x-axis
plot([.1, N_model+1], [0, 0], 'k','LineWidth',lw);

if ~isempty(opts.title)
    title(opts.title);
end

end