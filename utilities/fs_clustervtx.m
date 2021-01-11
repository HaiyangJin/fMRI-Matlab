function [clusterNo, nCluster, iterNo] = fs_clustervtx(vtxIdx, nbrVtx, vtxValue, vtxStart)
% [clusterNo, nCluster, iterNo] = fs_clustervtx(vtxIdx, nbrVtx, vtxValue, vtxStart)
%
% This function assigns vtxIdx into different clusters based on their
% neighborhood vertices.
%
% Inputs:
%    vtxIdx         <integer array> Px1 integer array. Indices of vertices.
%    nbrVtx         <cell> neighborhood vertices for the corresponding
%                    vertex in vtxIdx. Can be obtained via
%                    fs_neighborvtx.m.
%    vtxValue       <numeric array> PxQ numeric array. Values for each
%                    vertex.
%    vtxStart       <integer> 
%
% Outputs
%    cluserNo       <integer array> PxQ integer array. The cluster index
%                    for each vertex.
%    nCluster       <integer> the number of clusters in total.
%    iterNo         <integer array> PxQ integer array. The iteration index
%                    for each vertex when they are assigned to one cluster.
%
% Created by Haiyang Jin (10-May-2020)

if ~exist('vtxValue', 'var') || isempty(vtxValue)
    vtxValue = ones(size(vtxIdx));
end
if ~exist('vtxStart', 'var') || isempty(vtxStart)
    vtxStart = [];
end

% assign zeros
clusterNo = zeros(size(vtxIdx));
iterNo = zeros(size(vtxIdx));

% default clusterNum
clusterNum = 0;

% repeated for different clusters
while ~all(clusterNo)
    
    clusterNum = clusterNum + 1;
    
    % find all un-assigned vertices
    unassign = vtxIdx(~clusterNo);
    
    if ~isempty(vtxStart) && any(ismember(vtxStart, vtxIdx))
        theVtx = vtxStart;
        vtxStart = [];
    else
        if ~isempty(vtxStart) && ~any(ismember(vtxStart, vtxIdx))
            warning('The vertex with strongest response is used as the starting point...');
        end
        % use the vertex whose absolute value is largest as the starting point
        [~, maxIdx] = max(abs(vtxValue(~clusterNo)));
        theVtx = unassign(maxIdx);
    end
    
    % iteration number restart for each cluster
    iterNum = 0;
    
    % find all vertices for this cluster
    while any(theVtx)
        
        iterNum = iterNum + 1;
        
        % find all vertices for this iteration
        theCluster = ismember(vtxIdx, theVtx);
        
        % assign the clusterNum and iterNum
        clusterNo(theCluster) = clusterNum;
        iterNo(theCluster) = iterNum;
        
        % make theVtx for next iteration
        theNbrVtx = unique(vertcat(nbrVtx{theCluster}));
        
        % only keep un-assigned vertices in this label
        theVtx = intersect(theNbrVtx, vtxIdx(clusterNo == 0));
        
    end  % any(theVtx)
    
end  % ~all(clusterNo)

% the total number of clusters
nCluster = clusterNum;

end