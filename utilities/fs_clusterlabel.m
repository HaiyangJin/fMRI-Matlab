function [clusterNo, nCluster, iterNo] = fs_clusterlabel(labelFn, subjCode, excludeRng)
% [clusterNo, nCluster, iterNo] = fs_clusterlabel(labelFn, subjCode, excludeRng)
%
% This function assigns the vertices in one label into contiguous clusters.
%
% Inputs:
%    labelFn       <string> the file name of the label file (without path).
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    excludeRng    <numeric vector> 1x2 numeric array. The minimum and
%                   maximum boundaries of the exclusion range. The
%                   exclusion range will be applied to the fifth column of
%                   the label file. Default is [0 0], i.e., all vertices
%                   will be included.
%
% Output:
%    clusterNo     <integer vector> Px1 intger. Cluster index for each
%                   vertex in the label file. -1 denotes the vertex is
%                   within the exclusion range.
%    nCluster      <integer> total number of the clusters.
%    iterNo        <integer vector> Px1 intger. Iteration index for each
%                   vertex in the label file. -1 denotes the vertex is
%                   within the exclusion range.
%
% Created by Haiyang Jin (10-May-2020)

%% Find vertices outside excludeRng

if ~exist('excludeRng', 'var') || isempty(excludeRng)
    excludeRng = [0 0];
end

% read the label
labelMat = fs_readlabel(labelFn, subjCode);

% find vertices outside the excludeRng
isCluster = labelMat(:, 5) <= excludeRng(1) | labelMat(:, 5) >= excludeRng(2);

% return if no vertices are outside the excludeRng
if ~any(isCluster)
    warning('All vertices are within the ''excludeRng (%d %d)''.', ...
        excludeRng(1), excludeRng(2));
    clusterNo = -ones(size(labelMat, 1), 1);
    nCluster = 0;
    iterNo = -ones(size(labelMat, 1), 1);
    return
end

%% Assign the cluster indices
% keep the labelMat for the cluster vertices
clusterMat = labelMat(isCluster, :);
clusterVtx = clusterMat(:, 1);

% obtain the neighborhood vertices
nbrVtx = fs_neighborvtx(clusterVtx, subjCode);

% assign the vertices into clusters
[theClusterNo, nCluster, theIterNo] = fs_clustervtx(clusterVtx, nbrVtx);

%% Save the cluster index information
% create vector for all vertices (with -1)
clusterNo = zeros(size(isCluster));
iterNo = zeros(size(isCluster));
clusterNo(~isCluster) = -1;
iterNo(~isCluster) = -1;

% save the cluster indices
clusterNo(isCluster) = theClusterNo;
iterNo(isCluster) = theIterNo;

end