function [clusterNo, nCluster, iterNo] = fs_clustervtx(vtxIdx, nbrVtx)
% [clusterNo, nCluster, iterNo] = fs_clustervtx(vtxIdx, nbrVtx)
%
% This function assigns vtxIdx into different clusters based on their
% neighborhood vertices.
%
% Inputs:
%    vtxIdx         <integer array> PxQ integer array. Indices of vertices.
%    nbrVtx         <cell> neighborhood vertices for the corresponding
%                    vertex in vtxIdx. Can be obtained via
%                    fs_neighborvtx.m.
%
% Outputs
%    cluserNo       <integer array> PxQ integer array. The cluster index
%                    for each vertex.
%    nCluster       <integer> the number of clusters in total.
%    iterNo         <integer array> PxQ integer array. The iteration index
%                    for each vertex when they are assigned to one cluster.
%
% Created by Haiyang Jin (10-May-2020)

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
    
    % use the first as starting point to find cluster
    theVtx = unassign(1);
    
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