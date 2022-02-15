function [cenInfo, D] = fs_labelcenter(labelFn, subjCode, varargin)
% [cenInfo, D] = fs_labelcenter(labelFn, subjCode, varargin)
%
% Identify the label center (for label files on the surface). The label 
% (ROI) center is defined as the vertex/voxel whose (sum/average) geodesic
% (or Euclidian) distances from all other vertices/voxels are shortest. 
%
% Inputs:
%    labelFn         <str> filename of the label file (with or without
%                     path). If path is included in labelFn, [subjCode]
%                     will be ignored. 
%                 OR <vec> a vector of vertex indices.
%    subjCode        <str> subject code in $SUBJECTS_DIR. Default is 
%                     'fsaverage'.
%
% Varargin:
%    .surface        <str> the specific surface to be used to calculate the
%                     distiance. The hemisphere information should match
%                     the label file. Default is the ?h.white. 
%                 OR <cell> 1x2 num cell. [coord, faces]. The vertex
%                     indices should start from 1. coord: Px3; faces: Qx3.
%    .distmetric     <str> 'euclidean', 'dijkstra', or 'geodesic' (default).
%
% Outputs:
%     cenInfo        <num vec> 1x4. The information of the "center" vertex. 
%                     The four values are vertex index, x-, y-, 
%                     z-corrdinates on opts.surface. 
%     D              <mat> the distance between vertices in the labels. 
%
% Dependency:
%     surfing toolbox (and Fast Marching toolbox (Peyre)).
%
% Created by Haiyang Jin (2022-Jan-12)

if nargin < 2
    fprintf('Usage: [cenInfo, D] = fs_labelcenter(labelFn, subjCode, varargin);\n');
    return;
end

%% Inputs
defaultOpts = struct( ...
    'surface', '', ...
    'distmetric', 'geodesic');
opts = fm_mergestruct(defaultOpts, varargin);

if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
    warning('''fsaverage'' is used as ''subjCode'' by default.');
end

% read the label file into label matrix
if ischar(labelFn)
    labelMat = fs_readlabel(labelFn, subjCode);
else
    labelMat = labelFn;
end
vtxidx = labelMat(:,1);

% the default surface if succificent information is provided
if isempty(opts.surface) 
    assert(ischar(labelFn), 'Please define the surface to be used.')
    opts.surface = [fm_2hemi(labelFn) '.white'];
end

if ischar(opts.surface)
    [coords, faces] = fs_readsurf(opts.surface, subjCode);
else
    coords = opts.surface{1};
    faces = opts.surface{2};
end

%% Compute the distance matrix
switch opts.distmetric
    case 'euclidean'
        D = squareform(pdist(coords(vtxidx, :))); 

    case 'geodesic'
        % modified from surfing_circleROI.m
        [sc, sf, si] = surfing_subsurface(coords, faces, vtxidx, []);
        % this requires the Fast Marching toolbox (Peyre)
        Dcell = arrayfun(@(x) perform_fast_marching_mesh(sc, sf, x), si, 'uni', false);
        % convert D from cell to mat
        Dmat = horzcat(Dcell{:});
        % only keep distances between vertices in the label
        D = Dmat(si, :);

    case 'dijkstra'
        % modified from surfing_circleROI.m
        [sc, sf, si] = surfing_subsurface(coords, faces, vtxidx, []);
        Dcell = arrayfun(@(x) surfing_dijkstradist(sc', sf', x), si, 'uni', false);
        % convert D from cell to mat
        Dmat = horzcat(Dcell{:});
        % only keep distances between vertices in the label
        D = Dmat(si, :);
end

%% The average distances to other vertices  
Dsum = sum(D, 2); % sum of each row/vertex
[~, minidx] = min(Dsum);
minIdx = vtxidx(minidx);
cenInfo = [minIdx, coords(minIdx, :)];

end