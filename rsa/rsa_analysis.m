function [ds_result, fig] = rsa_analysis(ds_subj, ds_model, nrow, varargin)
% ds_result = rsa_analysis(ds_subj, ds_model, nrow, varargin)
%
% Perform statistical inferential analysis and plot.
%
% Inputs:
%    ds_subj       <struct> ds of subjects. Each column in .samples is one
%                   (reference) RDM and the third dimension in .samples is
%                   participants.
%    ds_model      <struct> ds of candidate models. Each column in .samples
%                   is one candidate model (RDM).
%    nrow          <int> number of rows in subplot().
%
% Varargin:
%    .position     <vec> the position of the output plot.
%    .xstart       <num> where to start plotting along the x-axis. Default
%                   to .05.
%    .ystart       <num> where to start plotting along the y-axis. Default
%                   to .15.
%    .xratio       <num> the porportion to plot x per figure. Default to .8.
%    .yratio       <num> the porportion to plot y per figure. Default to .7.
%
% Output:
%    ds_result     <struct> contains a series of results (used in
%                   plotting).
%
% Created by Haiyang Jin (2022-Aug-29)

if ~exist('nrow', 'var') || isempty(nrow)
    nrow = 1;
end

defaultOpts = struct( ...
    'position', [], ...
    'xstart', .05, ...
    'ystart', .15, ...
    'xratio', .8, ...
    'yratio', .7 ...
    );
opts = fm_mergestruct(defaultOpts, varargin);

%% Gather information for plotting
% Inference: compare brain RDMs to model RDMs
ds_cmp_subj = rsa_compare(ds_subj, ds_model);
% statistical reference
ds_rank_one = rsa_signrank(ds_cmp_subj, 1);
ds_rank_two = rsa_signrank(ds_cmp_subj, 2);

% Descriptive: average and noise ceiling
ds_avg = rsa_avg(ds_cmp_subj, [], [], 3, 1);
[ub, lb] = rsa_noiseceiling(ds_subj);

% save output
ds_result = struct;
ds_result.ds_cmp_subj = ds_cmp_subj;
ds_result.ds_rank_one = ds_rank_one;
ds_result.ds_rank_two = ds_rank_two;
ds_result.ds_avg = ds_avg;
ds_result.noiseceiling = [ub, lb];

%% Positions for subplots
% ncol for subplot
N_ref = size(ds_avg.samples, 2);
if N_ref > 1
    ncol = ceil(N_ref / nrow);
else
    ncol = 1;
end

if isempty(opts.position)
    opts.position = 100+[0 0 400*ncol 400*nrow];
end

x_row = .95 / ncol;
y_col = .95 / nrow;

%% Plotting
fig = figure('DefaultAxesFontSize',14);
set(gcf,'Position', opts.position);

% plot each subplot separately
for isub = 1:N_ref

    cor = ds_avg.samples(:,isub, 1);
    cor_se = ds_avg.samples(:,isub,2);
    N_subj = unique(ds_avg.samples(:,isub,3));
    modelnames = ds_avg.sa.models;
    noiseceiling = [ub(isub), lb(isub)];
    p_one_vec = ds_rank_one.samples(:, isub, 1);
    p_two_mat = rsa_vec2rdm(ds_rank_two.samples(:,isub,1), 1);

    rsa_plot(cor, cor_se, N_subj, noiseceiling, 'modelnames', modelnames, ...
        'pone_vec', p_one_vec, 'ptwo_mat', p_two_mat, 'subplot', [nrow, ncol, isub], ...
        'subposi', [opts.xstart+(mod(isub-1,ncol))*x_row, ...
        opts.ystart+(floor(isub/ncol))*y_col, ...
        x_row*opts.xratio, y_col*opts.yratio], ...
        'fig_handle', fig, 'title', ds_subj.fa.labels{isub}, varargin{:});


end

end