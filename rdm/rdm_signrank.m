function ds_sigrank = rdm_signrank(ds_cmp, sided)
% ds_sigrank = rdm_signrank(ds_cmp, sided)
%
% Perform sigrank tests. For "the relatedness of each candidate RDM to the 
% reference RDM", one-sided test should be used (sided=1); For "Whether two
% candidate RDMs differ in their relatedness to the reference RDM",
% two-sided test should be used (sided=2).
%
% Inputs:
%     ds_cmp      <struct> the relatedness between reference model (brain
%                  RDM) and candidate model (model RDM) for each participant
%                  separately. Usually obtained from rdm_compare().
%
%     sided       <int> 1 (default): one-sided tests. Or 2 for two-sided
%                  test. 
%
% Output:
%     ds_sigrank  <struct> output result ds.
%
% Created by Haiyang Jin (2022-Aug-25)

if nargin < 1
    fprintf('Usage: ds_sigrank = rdm_signrank(ds_cmp, sided);\n');
    return
end

if ~exist('sided', 'var') || isempty(sided)
    sided = 1;
end

switch sided

    case 1 % one-sided test (whether larger than 0)

        %% Generate samples
        % convert samples into cell
        sample_cell = num2cell(ds_cmp.samples, 3);
        sample_cell = cellfun(@(x) squeeze(x), sample_cell, 'uni', false);

        % remove nan (and count N before and after)
        N_withnan = cellfun(@length, sample_cell);
        sample_cell = cellfun(@rmmissing, sample_cell, 'uni', false);
        N = cellfun(@length, sample_cell);

        % rsa.stat.signrank_onesided() is from RSA toolbox
        medians = cellfun(@median, sample_cell);
        p = cellfun(@rsa.stat.signrank_onesided, sample_cell);
        % h does not seem to be correct in rsa.stat.signrank_onesided()
        % so re-caulculate here
        h = p <= 0.05;

        %% make ds_sigrank
        ds_sigrank = ds_cmp;
        ds_sigrank.pa.labels = {'p', 'h', 'median', 'N', 'N_withnan'}';
        ds_sigrank.samples = cat(3, p, h, medians, N, N_withnan);
        ds_sigrank.a.method = 'rsa.stat.signrank_onesided';

    case 2 % two-sided test (which is larger)

        %% Generate samples
        % convert samples into cell
        sample_cell = num2cell(ds_cmp.samples, [1,3]);
        sample_cell = cellfun(@(x) squeeze(x), sample_cell, 'uni', false);

        % remove nan (and count N before and after)
        N_withnan = cellfun(@(x) size(x,2), sample_cell);
        sample_cell = cellfun(@(x) rmmissing(x')', sample_cell, 'uni', false);
        N = cellfun(@(x) size(x,2), sample_cell);

        % two-sided rank test
        [p, h] = cellfun(@sigrank_pair, sample_cell, 'uni', false);

        % .sa.labels
        combs = nchoosek(1:size(ds_cmp.samples,1),2);
        labels = arrayfun(@(x) [ds_cmp.sa.models{combs(x,1)}, ...
            '-', ds_cmp.sa.models{combs(x,2)}], 1:size(combs,1), 'uni', false)';

        % make ds_sigrank
        ds_sigrank = ds_cmp;
        ds_sigrank.sa = [];
        ds_sigrank.sa.labels = labels;
        ds_sigrank.pa.labels = {'p', 'h'}';
        ds_sigrank.samples = cat(3, horzcat(p{:}), horzcat(h{:}));
        ds_sigrank.fa.N = N;
        ds_sigrank.fa.N_withnan = N_withnan;
        ds_sigrank.a.method = 'signrank_two-sided';
        ds_sigrank.a.conditions = ds_cmp.sa.models;

end %switch

end %function


function [p, h] = sigrank_pair(cmp_mat)
% perform two-sided sig rank test for each pair of rows in cmp_mat

combs = nchoosek(1:size(cmp_mat,1),2);

[p, h] = arrayfun(@(x) signrank( ...
    cmp_mat(combs(x,1),:), ...
    cmp_mat(combs(x,2),:),'alpha',0.05,'method','exact'), ...
    1:size(combs,1));

p = p';
h = h';

end %sigrank_pair