function rdms = rdm_triuvec2rdm(vec, Pceil)
% rdms = rdm_triuvec2rdm(vec, Pceil)
%
% (May not be useful) Convert a vector (which should be obtained from
% rdm_triu2vec() to the upper corner of RDM.
%
% Inputs:
%    vec         <num array> N x Q array. Each row is one participant and
%                 columns are for different pairs in RDM. 
%                 Q = (1+(P-1))*(P-1)/2.
%    Pceil       <int> [this is a weird setting] the possible maximum of P,
%                 i.e., the first and second dimension in the output RDM.
%
% Output: 
%    rdms        <num array> P x P x N array. P x P is a RDM for one
%                 participant and there are N participants in total.
% 
% Created by Haiyang Jin (2021-11-16)
%
% See also:
% rdm_triu2vec

if ~exist('Pceil', 'var') || isempty(Pceil)
    Pceil = 50;
end

% Q = (1 + P-1)*(P-1)/2 
Qs = arrayfun(@(p) p*(p-1)/2, 1:Pceil);

% find P
[N, Q] = size(vec);
P = find(Qs==Q);
if isempty(P)
    error('Cannot decide P with the Q (%d).', Q);
end

% empty output
rdms = NaN(P, P, N);

% convert vec to upper corner of RDM
boo_triu = repmat(logical(triu(ones(P),1)), 1, 1, N);
rdms(boo_triu) = vec';

end