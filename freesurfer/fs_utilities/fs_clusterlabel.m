function [clusterIdx, nCluster, iterNo] = fs_clusterlabel(labelFn, subjCode, fmin, hemi)
% [clusterIdx, nCluster, iterNo] = fs_clusterlabel(labelFn, subjCode, fmin, hemi)
%
% This function assigns the vertices in one label into contiguous clusters.
%
% Inputs:
%    labelFn       <string> the file name of the label file (without path).
%               or <numeric array> The first column has to be the vertex
%                   indices. 'fmin' will be ignored if the number of column
%                   is smaller than 5.
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    fmin          <numeric> The (absolute) minimum value for vertices to
%                   be used for assigning a cluster index. Default is 0,
%                   i.e., all vertices will be used.
%    hemi          <string> 'lh' or 'rh'. hemi will be used when labelFn is
%                   a numeric array. Which hemisphere is labelFn from.
%
% Output:
%    clusterIdx    <integer vector> Px1 intger. Cluster index for each
%                   vertex in the label file. -1 denotes the vertex's value
%                   is smaller than 'fmin'.
%    nCluster      <integer> total number of the clusters.
%    iterNo        <integer vector> Px1 intger. Iteration index for each
%                   vertex in the label file. -1 denotes the vertex's value
%                   is smaller than 'fmin'.
%
% Created by Haiyang Jin (10-May-2020)

%% Find vertices larger than fmin

if ~exist('fmin', 'var') || isempty(fmin)
    fmin = [];
end

if ischar(labelFn)
    % read the label
    labelMat = fs_readlabel(labelFn, subjCode);
    hemi = fs_2hemi(labelFn);
else
    labelMat = labelFn;
    assert(logical(exist('hemi', 'var')), ['Please define ''hemi'' when '''...
        'labelFn'' is a numeric matrix.']);
end

if size(labelMat, 2) >= 5 && ~isempty(fmin)
    % all values have to be the same direction
    values = labelMat(:, 5);
    assert(all(values>=0)||all(values<=0), ...
        'Values have to be all positive or all negative.');
    
    % find vertices larger than fmin
    isCluster = abs(values) >= abs(fmin);
    vtxValue = labelMat(isCluster, 5);
else
    isCluster = true(size(labelMat, 1), 1);
    vtxValue = [];
end

% return if no vertices are larger than fmin
if ~any(isCluster) 
    if ~isempty(vtxValue) && any(vtxValue ~= 0)
        warning('Values for all vertices are smaller than ''fmin (%.1f)''.', fmin);
    end
    clusterIdx = -ones(size(labelMat, 1), 1);
    nCluster = 0;
    iterNo = -ones(size(labelMat, 1), 1);
    return;
end

%% Assign the cluster indices
% keep the labelMat for the cluster vertices
clusterVtx = labelMat(isCluster, 1);

% obtain the neighborhood vertices
[~, nbrVtx] = fs_neighborvtx(clusterVtx, hemi, subjCode);

% assign the vertices into clusters
[theClusterNo, nCluster, theIterNo] = sf_clustervtx(clusterVtx, nbrVtx, vtxValue);

%% Save the cluster index information
% create vector for all vertices (with -1)
clusterIdx = zeros(size(isCluster));
iterNo = zeros(size(isCluster));
clusterIdx(~isCluster) = -1;
iterNo(~isCluster) = -1;

% save the cluster indices
clusterIdx(isCluster) = theClusterNo;
iterNo(isCluster) = theIterNo;

end