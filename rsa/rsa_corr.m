function outcorr = rsa_corr(X, Y, type)
% outcorr = rsa_corr(X, Y, type)
% 
% Calcualte the correlations between X and Y.
%
% Inputs:
%    X       <num mat> each column is one RDM.
%    Y       <num mat> each column is one RDM. Default to X.
%    type    <str> the method used to calculate the correlations. Default
%             to Kendall's Tau a. Other avaiable options are those in
%             corr().
%
% Output:
%    outcorr <num> correlation coefficients. 
%
% Created by Haiyang Jin (2022-Aug-26)

if nargin < 1
    fprintf('Usage: outcorr = rsa_corr(X, Y, type);\n');
    return
end

if ~exist('Y', 'var') || isempty(Y)
    Y = X;
end

if ~exist('type', 'var') || isempty(type)
    type = 'kendall_taua';
end

%% Calculate correlations

N_x = size(X, 2);
N_y = size(Y, 2);

% use different method to compare models
switch type

    case 'kendall_taua'

        [tmp_y, tmp_x] = ndgrid(1:N_y, 1:N_x);
        
        out = arrayfun(@(a,b) rsa.stat.rankCorr_Kendall_taua( ...
            Y(:,a), X(:,b)), tmp_y(:), tmp_x(:));

        outcorr = reshape(out, N_y, N_x);

    case {'Kendall', 'Spearman', 'Pearson'}

        outcorr = corr(Y, X, 'type', type);

    otherwise
        error('Cannot identify the correaltion type (%s).', type);

end %switch type

end