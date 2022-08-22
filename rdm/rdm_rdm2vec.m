function vec = rdm_rdm2vec(rdms, tri)
% vec = rdm_rdm2vec(rdms, tri)
%
% Converts a RDM (P x P) into a row vector of (1+(P-1))*(P-1)/2 values. A
% good alternative is squareform().
%
% Inputs:
%    rdms        <num array> P x P x N array. P x P is a RDM for one
%                 participant and there are N participants in total.
%             OR <num array> Q x N array. Q is the number of pairs in RDM
%                 and N is the number of participants.
%    tri         <str> whether it is lower {'l', 'low', 'lower'} or upper
%                 {'u', 'up', 'upper'} [default] triangle vector.
%
% Output:
%    vec         <num array> N x (1+(P-1))*(P-1)/2 array.
%
% Created by Haiyang Jin (2021-11-16)
%
% See also:
% rdm_vec2rdm

if ~exist('tri', 'var') || isempty(tri)
    tri = 'lower';
    warning('The output vector will come from the lower triangle of RDM.');
end
switch tri
    case {'l', 'low', 'lower'}
        thefunc = @tril;
        theidx = -1;
    case {'u', 'up', 'upper'}
        thefunc = @triu;
        theidx = 1;
end

assert(ismember(ndims(rdms), [2,3]), '<rdms> should have 2 or 3 dimensions.');

% the first two dimension sizes
[P1, P2, N] = size(rdms, 1, 2, 3);
assert(P1==P2, 'The first two dimensions of <rdms> have to be the same');

% save the triangle of rdms as one row vector
boo_tri = logical(thefunc(ones(P1),theidx));
vec = reshape(rdms(repmat(boo_tri, 1, 1, N)), [], N)';

end