function noise = rsa_noiseceiling(rdms, meanout)
% noise = rsa_noiseceiling(rdms, meanout)
%
% Calculate the noise ceiling for RDMs. The lower bound of the noise 
% ceiling was estimated by calculating the Pearson correlation of the brain
% RDM for each participant with the average brain RDM across all other 
% participants (after z scoring the brain RDM for each participant). 
% The upper bound of the noise ceiling was estimated by computing the 
% Pearson correlation of the brain RDM for each participant with the 
% average brain RDM across all participants (after z scoring the brain RDM 
% for each participant). More see Reference.
%
% Inputs:
%    rdms        <num array> P x P x N array. P x P is a RDM for one
%                 participant and there are N participants in total.
%             OR <num array> Q x N array. Q is the number of pairs in RDM and
%                 N is the number of participants.
%    meanout     <str> whether additional steps are applied to the output
%                 cor. 'mean': directly get the mean of all values in cor;
%                 'tanh': apply atanh, calculate the mean, and apply tanh;
%                 'raw': do nothing.
%
% Output:
%    noise       <num> 1 x 2 vector; the lower and upper boundary of the 
%                 noise ceiling.
%
% Reference:
% Nili, H., Wingfield, C., Walther, A., Su, L., Marslen-Wilson, W., &
%   Kriegeskorte, N. (2014). A Toolbox for Representational Similarity
%   Analysis. PLoS Computational Biology, 10(4), e1003553.
%   https://doi.org/10.1371/journal.pcbi.1003553
% Tsantani, M., Kriegeskorte, N., Storrs, K., Williams, A. L., McGettigan, 
%   C., & Garrido, L. (2021). FFA and OFA Encode Distinct Types of Face 
%   Identity Information. The Journal of Neuroscience, 41(9), 1952–1969. 
%   https://doi.org/10.1523/JNEUROSCI.1449-20.2020
%
% Created by Haiyang Jin (2021-11-15)

if nargin < 1
    fprintf('Usage: noise = rsa_noiseceiling(rdms, meanout);\n');
    return
end

% output
noise = NaN(1, 2);

if ndims(rdms) == 3
    [P1, P2, N] = size(rdms);
    assert(P1==P2, ['The first two dimensions of <rdms> have to be the same' ...
        ' when there are 3 dimensions in <rdms>.'])

    % from 3d to 2d: save the upper right corner of rdms as one row vector
    boo_triu = logical(triu(ones(P1),1));
    rdms = reshape(rdms(repmat(boo_triu, 1, 1, N)), [], N)';
elseif ndims(rdms) > 3
    error('The dimension of <rdms> should be 2 or 3.')
end

if ~exist('meanout', 'var') || isempty(meanout)
    meanout = 'mean';
end

% Standardized rdms for each participant separately (column)
z_rdms = zscore(rdms, [], 1);

% noise ceiling
noise(1) = rsa_reliability(z_rdms, 0, meanout);
noise(2) = rsa_reliability(z_rdms, 1, meanout);

end