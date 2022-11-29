function D = sf_geodesic(coords, faces, vtxsurf, vtxfrom, vtxto, distmetric)
% D = sf_geodesic(coords, faces, vtxsurf, vtxfrom, vtxto, distmetric)
% 
% Calculate the geodesic (dijkstra) distances between {vtxfrom} and
% {vtxto}.
%
% Inputs:
%    coords      <mat> Px3, vertex coordinates
%    faces       <mat> Qx3, vertex indices for each face.
%    vtxsurf     <int vec> a list of vertex indices for the sub-surface, 
%                 which includes {vtxfrom} and {vtxto}, as well as the 
%                 vertices connecting them. Default to all vertices in {coords}.
%    vtxfrom     <int vec> M, a list of vertex indices that will be the
%                 starting points for the distances. Default to {vtxsurf}.
%    vtxto       <int vec> N, a list of vertex indices that will be the
%                 ending points for the distances. Default to {vtxsurf}.
%    distmetric  <str> method to be used to calculate the distance. Default
%                 to 'geodesic'; the other option is 'dijkstra'.%    
%
% Output:
%    D           <num mat> NxM. Each column is one starting vertex and each
%                 row is one ending vertex.
%    
% Creeatd by Haiyang Jin (2022-Nov-24)

%% Deal with inputs
if nargin < 2
    fprintf('Usage: D = sf_geodesic(coords, faces, vtxsurf, vtxfrom, vtxto, distmetric)\n');
    return;
end

if ~exist('vtxsurf', 'var') || isempty(vtxsurf)
    vtxsurf = 1:size(coords, 1);
end

if ~exist('vtxfrom', 'var') || isempty(vtxfrom)
    vtxfrom = vtxsurf; % just some random numbers
end
assert(all(ismember(vtxfrom, vtxsurf)), ['vertices in {vtxfrom} should be ' ...
    'part of those in {vtxsurf}']);
if length(vtxfrom)>1000 
    warning('It will take some time (maybe forever)...')
end

if ~exist('vtxto', 'var') || isempty(vtxto)
    vtxto = vtxsurf; % just some random numbers
end
assert(all(ismember(vtxto, vtxsurf)), ['vertices in {vtxto} should be ' ...
    'part of those in {vtxsurf}']);

if ~exist('distmetric', 'var') || isempty(distmetric)
    distmetric = 'geodesic'; % dijkstra
end

%% Calculate the geodesic distances

% prepare the subsurface
v2f=surfing_nodeidxs2faceidxs(faces');
[sc, sf, ~, nsel] = surfing_subsurface(coords, faces, vtxsurf, [], v2f);

svtxfrom = arrayfun(@(x) find(x==nsel), vtxfrom);
svtxto = arrayfun(@(x) find(x==nsel), vtxto);

% calculate the distance
% modified from surfing_circleROI.m
switch distmetric
    case 'geodesic'
        % this requires the Fast Marching toolbox (Peyre)
        Dcell = arrayfun(@(x) perform_fast_marching_mesh(sc, sf, x), svtxfrom, 'uni', false);

    case 'dijkstra'
        Dcell = arrayfun(@(x) surfing_dijkstradist(sc', sf', x), svtxfrom, 'uni', false);
end

% convert D from cell to mat
Dmat = horzcat(Dcell{:});
D = Dmat(svtxto, :);

end