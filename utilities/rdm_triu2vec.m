function vec = rdm_triu2vec(rdms)
% vec = rdm_triu2vec(rdms)
%
% Converts a RDM (P x P) into a row vector of (1+(P-1))*(P-1)/2 values.
%
% Inputs:
%    rdms        <num array> P x P x N array. P x P is a RDM for one
%                 participant and there are N participants in total.
%             OR <num array> Q x N array. Q is the number of pairs in RDM
%                 and N is the number of participants.
% Output:
%    vec         <num array> N x (1+(P-1))*(P-1)/2 array.
%
% Created by Haiyang Jin (2021-11-16)
%
% See also:
% rdm_triuvec2rdm

assert(ismember(ndims(rdms), [2,3]), '<rdms> should have 2 or 3 dimensions.');

% the first two dimension sizes
[P1, P2, N] = size(rdms, 1, 2, 3);
assert(P1==P2, 'The first two dimensions of <rdms> have to be the same');

% save the upper right corner of rdms as one row vector
boo_triu = logical(triu(ones(P1),1));
vec = reshape(rdms(repmat(boo_triu, 1, 1, N)), [], N)';

end