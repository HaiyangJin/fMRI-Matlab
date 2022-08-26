function [ub, lb] = rsa_noiseceiling(ds_subj, type, method)
% [ub, lb] = rsa_noiseceiling(ds_subj, type, method)
%
% Calculate the noise ceiling for RDMs. The lower bound of the noise 
% ceiling was estimated by calculating the correlation of the brain
% RDM for each participant with the average brain RDM across all other 
% participants (after the appropriate transformation). 
% The upper bound of the noise ceiling was estimated by computing the 
% correlation of the brain RDM for each participant with the 
% average brain RDM across all participants (after the appropriate 
% transformation). More see Reference.
%
% Inputs:
%    ds_subj     <struct> subject RDMs. Each column in .samples is one brain
%                 RDM (vector). The third dimension is the participant.
%    type        <str> correlation to be used to compare RDMs. Default to
%                 'kendall_taua' (from rsatoolbox). Other options are
%                 methods avaiable in corr in matlab (statistics toolbox).
%                 more see rsa_corr().
%    method     <str> whether additional steps are applied to the output
%                 cor. 'mean': directly get the mean of upper and lower boundaries;
%                 'tanh': apply atanh, calculate the mean, and apply tanh;
%                 'raw': do nothing (just output the matrix).
%
% Output:
%    ub           <num> The upper boundary of the noise ceiling.
%    lb           <num> The lower boundary of the noise ceiling.
%
% Reference:
% Nili, H., Wingfield, C., Walther, A., Su, L., Marslen-Wilson, W., &
%   Kriegeskorte, N. (2014). A Toolbox for Representational Similarity
%   Analysis. PLoS Computational Biology, 10(4), e1003553.
%   https://doi.org/10.1371/journal.pcbi.1003553
%
% Created by Haiyang Jin (2021-11-15)

if nargin < 1
    fprintf('Usage: [ub, lb] = rsa_noiseceiling(ds_subj, type, method);\n');
    return
end

if ~exist('type', 'var') || isempty(type)
    type = 'kendall_taua';
end

if ~exist('method', 'var') || isempty(method)
    method = 'mean';
end

% convert samples to cell
sample_cell = num2cell(ds_subj.samples, 1);

%% Apply transformations
switch type
    case {'kendall_taua', 'Spearman'}
        % rank-transform
        sample_cell = cellfun(@tiedrank, sample_cell, 'uni', false);

    case 'Pearson'
        % z-transformed
        sample_cell = cellfun(@zscore, sample_cell, 'uni', false);
end %switch type

samples = cell2mat(sample_cell);

%% Noise ceiling - upper boundaries
sample_avg = mean(samples, 3, 'omitnan');

% correlation between the average RDM and subject RDM
corr_cell = arrayfun(@(x) ...
    rsa_corr(squeeze(samples(:,x,:)), sample_avg(:,x), type), ...
    1:size(sample_avg, 2), 'uni', false);

corr_ub = vertcat(corr_cell{:})';

% apply transform if needed
ub = transformmean(corr_ub, method);

%% Noise ceiling - lower boundaries
corr_lb = nan(size(samples, 3), size(samples, 2));

for iSubj = 1:size(samples, 3)
    
    % leave-one-out mean
    tmpsample = samples;
    tmpsample(:,:,iSubj) = [];
    tmpavg = mean(tmpsample, 3, 'omitnan'); 

    % leave-out-out correlation
    corr_lb(iSubj,:) = arrayfun(@(x) ...
        rsa_corr(squeeze(samples(:,x,iSubj)), tmpavg(:,x), type), ...
        1:size(tmpavg, 2));
    
end %iSubj

% apply transform if needed
lb = transformmean(corr_lb, method);


end %function

function cor = transformmean(corr_mat, method)
% corr_mat: each column is one reference model and each row is one
% participant.

% apply tansformation to the output
switch method
    case 'mean'
        % do not apply any transformation
        cor = mean(corr_mat, 1, 'omitnan');

    case {'tanh', 'atanh'}
        % apply atanh()
        if any(ismember([max(corr_mat), min(corr_mat)], [-1, 1]))
            warning(['The output (cor) may not make sense as at least one ' ...
                'of the correaltions is 1 or -1.']);
        end
        cor = tanh(mean(atanh(corr_mat), 1, 'omitnan'));

    case 'raw' % keep what it is
    otherwise
        error('The option of %s as <meanout> is not avaiable.')
end %switch method

end %method
