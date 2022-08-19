function rdms = rdm_vec2rdm(vec, tri, chanceValue, Pceil)
% rdms = rdm_vec2rdm(vec, tri, Pceil)
%
% (May not be useful) Convert a vector (which should be obtained from
% RDM) to RDM.
%
% Inputs:
%    vec         <num array> N x Q array. Each row is one participant and
%                 columns are for different pairs in RDM. 
%                 Q = (1+(P-1))*(P-1)/2.
%    tri         <str> whether it is lower {'l', 'low', 'lower'} or upper
%                 {'u', 'up', 'upper'} [default] triangle vector.
%    chanceValue <num> the default chance value used to create the array.
%                 Default is 0.
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
% rdm_rdm2vec

if ~exist('tri', 'var') || isempty(tri)
    tri = 'lower';
    warning('The input vector was assumed to come from the lower triangle of RDM.');
end
switch tri
    case {'l', 'low', 'lower'}
        thefunc = @tril;
        theidx = -1;
    case {'u', 'up', 'upper'}
        thefunc = @triu;
        theidx = 1;
end

if ~exist('chanceValue', 'var') || isempty(chanceValue)
    chanceValue = 0;
end

if ~exist('Pceil', 'var') || isempty(Pceil)
    Pceil = 500;
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
tri1 = zeros(P, P, N);

% convert vec to one triangle of RDM
boo_tri1 = repmat(logical(thefunc(ones(P),theidx)), 1, 1, N);
tri1(boo_tri1) = vec';

% copy one tri to the other tri
tri2 = arrayfun(@(x) thefunc(tri1(:,:,x),1)', 1:size(tri1,3), 'uni', false); 

% make the diagnal 0
rdms = tri1 + cat(3, tri2{:});

% assign the chancel value
rdms(repmat(logical(eye(P)), 1, 1, N)) = chanceValue;

end