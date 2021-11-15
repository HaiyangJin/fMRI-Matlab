function cor = rdm_reliability(rdms, avgall, meanout)
% cor = rdm_reliability(rdms, avgall, meanout)
%
% Calcuate the intersubject reliability by estimating the correlations
% between each participant's RDM with the average RDM (with or without own
% participant).
%
% Inputs:
%    rdms        <num array> P x P x N array. P x P is a RDM for one
%                 participant and there are N participants in total.
%             OR <num array> Q x N array. Q is the number of pairs in RDM and
%                 N is the number of participants.
%    avgall      <boo> whether calculate average RDM across all
%                 participants: 1 (default): average of all participants;
%                 0: average of all OTHER participants.
%    meanout     <str> whether additional steps are applied to the output
%                 cor. 'mean': directly get the mean of all values in cor;
%                 'tanh': apply atanh, calculate the mean, and apply tanh;
%                 'raw': do nothing.
%
% Output:
%    cor         <num> the (averaged) correlation (i.e., the intersubject
%                 reliability).
%
% Reference:
% Tsantani, M., Kriegeskorte, N., Storrs, K., Williams, A. L., McGettigan, 
%   C., & Garrido, L. (2021). FFA and OFA Encode Distinct Types of Face 
%   Identity Information. The Journal of Neuroscience, 41(9), 1952–1969. 
%   https://doi.org/10.1523/JNEUROSCI.1449-20.2020
%
% Created by Haiyang Jin (2021-11-14)

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

if ~exist('avgall', 'var') || isempty(avgall)
    avgall = 1;
end

if ~exist('meanout', 'var') || isempty(meanout)
    meanout = 'mean';
end

%% Calculate intersubject reliability
nSubj = size(rdms, 2);

if avgall
    % RDM average across all participants
    cor = arrayfun(@(x) corr(rdms(:,x), mean(rdms, 2)), 1:nSubj);
else
    % RDM average across all OTHER participants
    cor = NaN(1, nSubj);

    for iSubj = 1:nSubj
        % remove the own participant
        tmprdms = rdms;
        tmprdms(:,iSubj) = NaN;

        cor(1, iSubj)=corr(rdms(:,iSubj), mean(tmprdms,2, 'omitnan'));
    end
end

% apply extra calculation to the output
switch meanout
    case 'mean'
        cor = mean(cor);
    case {'tanh', 'atanh'}
        if any(ismember(range(cor), [-1, 1]))
            warning(['The output (cor) may not make sense as at least one ' ...
                'of the correaltions is 1 or -1.']);
        end
        cor = tanh(mean(atanh(cor)));
    case 'raw' % keep what it is
    otherwise
        error('The option of %s as <meanout> is not avaiable.')
end

end