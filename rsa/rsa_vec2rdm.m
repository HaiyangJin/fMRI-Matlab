function rdms = rsa_vec2rdm(vec, diagValue, Pceil)
% rdms = rsa_vec2rdm(vec, chanceValue, Pceil)
%
% (May not be useful) Convert a vector (which should be obtained from
% RDM) to RDM.
%
% Inputs:
%    vec         <num array> N x Q array. Each column is one RDM vector and
%                 rows are for different pairs in RDM. 
%                 Q = (1+(P-1))*(P-1)/2.
%    diagValue   <num> the default value to be displayed on the diagnoal.
%                 Default is 0.
%    Pceil       <int> [this is a weird setting] the possible maximum of P,
%                 i.e., the first and second dimension in the output RDM.
%
% Output: 
%    rdms        <num array> P x P x N array. P x P is one RDM there are N 
%                 RDMs in total.
% 
% Created by Haiyang Jin (2021-11-16)
%
% See also:
% rsa_rdm2vec

if nargin < 1
    fprintf('Usage: rdms = rsa_vec2rdm(vec, chanceValue, Pceil);\n');
end

if ~exist('diagValue', 'var') || isempty(diagValue)
    diagValue = 0;
end

if ~exist('Pceil', 'var') || isempty(Pceil)
    Pceil = 500;
end

% Q = (1 + P-1)*(P-1)/2 
Qs = arrayfun(@(p) p*(p-1)/2, 1:Pceil);

% find P
[Q, N] = size(vec);
P = find(Qs==Q);
if isempty(P)
    error('Cannot decide P with the Q (%d).', Q);
end

% empty output
rdms = NaN(P, P, N);

for irdm = 1:N

    therdm = squareform(vec(:, irdm));

    % set the diagnoal values
    therdm(logical(eye(P))) = diagValue;

    % save this rdm
    rdms(:,:,irdm) = therdm;

end %irdm

end %function