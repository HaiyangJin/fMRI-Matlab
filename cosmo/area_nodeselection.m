function [n2ns,radii,areaSize]= area_nodeselection(vtx, faces, areas, ...
    areaMax, radiusIni, dist_metric, progressstep)
% [n2ns,raddi,areaSize]= area_nodeselection(vtx, faces, areas, ...
%    areaMax, radiusIni, dist_metric, progressstep)
%
% This function selects vertices (neighbors) based on the total area. This
% function is used in cosmo_surficial_neighborhood_area.m (modified from
% cosmo_surficial_neighborhood.m).
%
% Inputs:
%    vtx            <numeric array> 3xP node coordinates for P nodes.
%    faces          <integer array> 3xQ face indices for Q faces.
%    areas          <numeric vector> 1xP vertex areas for P nodes.
%    areaMax        <numeric> the maximum area size (mm^2) for the
%                    neighbors. Default is 100.
%    radiusInt      <numeric> the initalized radius for identifying
%                    neighbors. Default is 5. 
%    dist_metric     'euclidean', 'dijkstra', or 'geodesic' (default).
%
% Output:
%    n2ns           <cell> Px1 cell, with n2ns{k} containing the indices of
%                    nodes within total areaMax from node k according to the
%                    specified distance metric.
%    radii          <numeric vector> Px1 radius of each searchlight.
%    areaSize       <numeric vector> Px1 total area size of each searchlight.
%
% Dependency:
%    surfing toolbox. (https://github.com/nno/surfing)
%
% Created by Haiyang Jin (13-Oct-2020)
%
% See also:
% surfing_nodeselection

if ~exist('areaMax', 'var') || isempty(areaMax)
    areaMax = 100;
end

if ~exist('radiusIni', 'var') || isempty(radiusIni) || radiusIni <= 0
    radiusIni = 5;
end

if ~exist('dist_metric', 'var') || isempty(dist_metric)
    dist_metric = 'geodesic';
end

if ~exist('progressstep', 'var') || isempty(progressstep)
    progressstep=100;
end
show_progress=~isempty(progressstep) && progressstep~=0;
clock_start=clock();
prev_msg='';

% for saving output
nVtx=size(vtx,2);
n2ns=cell(nVtx,1); % mapping from center node to surrounding nodes
radii = zeros(nVtx, 1);
areaSize = zeros(nVtx, 1);
sizes = zeros(nVtx,1);

% for speedup, precompute mapping
n2f=surfing_invertmapping(faces');


for iV = 1:nVtx
    
    thisArea = 0;
    radius = radiusIni;
    
    % obtain neighbors whose total area is larger than areaMax
    while thisArea < areaMax
        
        [coordidx, dist]= surfing_circleROI(vtx,faces,iV,radius,dist_metric,n2f);
        thisArea = sum(areas(coordidx, :));
        radius = radius + 1;
    end
    
    % only keep vertices closest to the center and the total area is just
    % below areaMax
    [~, index] = sort(dist);
    sortedIdx = coordidx(index);
    kept = cumsum(areas(sortedIdx)) < areaMax;
    
    % neighbors for this vertex/node
    thisNbr = sortedIdx(kept);
    
%     % this part can confirm all the vertices are contiguous, but too time-consuming
%     [~, nCluster] = fs_clustervtx(thisNbr, fs_neighborvtx(thisNbr, faces));
%     assert(nCluster ==1);
    
    % calcualte and save the output
    n2ns{iV, 1} = thisNbr;
    radii(iV, 1) = max(dist(kept));
    areaSize(iV, 1) = sum(areas(thisNbr));
    sizes(iV, 1) = numel(thisNbr);
    
    if show_progress && (iV<10 || mod(iV,progressstep)==0 || iV==nVtx)
        msg=sprintf('%.1f nodes per center', mean(sizes(1:iV)));
        prev_msg=surfing_timeremaining(clock_start,iV/nVtx,msg,prev_msg);
    end
    
end

end