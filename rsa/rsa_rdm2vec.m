function vec = rsa_rdm2vec(rdms)
% vec = rsa_rdm2vec(rdms)
%
% Converts a RDM (P x P) into a vector of (1+(P-1))*(P-1)/2 values.
%
% Inputs:
%    rdms        <num array> P x P x N array. P x P is a RDM for one
%                 participant and there are N participants in total.
%             OR <num array> Q x N array. Q is the number of pairs/value in
%                 RDM and N is the number of RDMs.
%
% Output:
%    vec         <num array> N x (1+(P-1))*(P-1)/2 array.
%
% Created by Haiyang Jin (2021-11-16)
%
% See also:
% rsa_vec2rdm

if nargin < 1
    fprintf('Usage: vec = rsa_rdm2vec(rdms);\n');
end

assert(ismember(ndims(rdms), [2,3]), '<rdms> should have 2 or 3 dimensions.');

% the first two dimension sizes
[P1, P2, N] = size(rdms, 1, 2, 3);
assert(P1==P2, 'The first two dimensions of <rdms> have to be the same');

% empty array to save output later
vec = NaN(nchoosek(P1, 2), N);

for irdm = 1:N
    
    therdm = rdms(:, :, irdm);

    % force the diagnoal to be 0
    therdm(logical(eye(P1))) = 0;

    % save the vec of this rdm
    vec(:,irdm) = squareform(therdm);

end %irdm

end %function