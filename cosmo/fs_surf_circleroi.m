function [coordidx,D,scoords,vORr] = fs_surf_circleroi(subjCode, vtx, radius, varargin)
% [coordidx,D,vORr] = fs_surf_circleroi(subjCode, vtx, radius, varargin)
%
% This function uses surfing_circleROI.m from surfing toolbox to get the
% ROI with different criteria. More see radius.
%
% Inputs:
%    subjCode        <string> subject code in $SUBJECTS_DIR.
%    vtx             <integer> the vertex index (in Matlab);
%                 or <string> gloal maximal filename.
%    radius          <copied from surfing_circleROI.m> the radius of the 
%                     circle; use [R C] to select C nodes with initial 
%                     radius R; use [R Inf A] to select X nodes whose area
%                     is about A mm^2 (just below A mm^2).
%                     [Radius, Count, Area]
%
% Varargin:
%    .hemi           <string> hemisphere. Not used when <vtx> is string.
%    .surf           <string> the surface used to calcualte the area.
%    .dismetric      <string> 'euclidean' or 'dijkstra' or 'geodesic' (default)
%
% Output:
%    coordidx:       <integer vec> 1xK vector with the K vertex indices 
%                     that are within distance RADIUS from the center
%                     vertex.
%    D:              <numeric vec> 1xK vector of the distances from 
%                     center vertex.
%    scoords:        <integer vec> 3xK matrix of coordinates of the 
%                     selected vertices
%    vORr:           <integer> output depends on radius.
%
% Created by Haiyang Jin (22-June-2021)

defaultOpts = struct();
defaultOpts.hemi = 'lh';
defaultOpts.surf = 'white';
defaultOpts.dismetric = 'geodesic';  % 'euclidean' or 'dijkstra'

opts = fm_mergestruct(defaultOpts, varargin{:});

% vtx
if ischar(vtx)
    opts.hemi = fs_2hemi(vtx); 
    vtx = fs_readgm(subjCode, vtx);
end

if isnan(vtx)
    coordidx = NaN;
    D = NaN;
    scoords = NaN;
    vORr = NaN;
    warning('Cannot find the vtx...');
    return;
end

[coords, faces] = fs_readsurf([opts.hemi, '.', opts.surf], subjCode);
n2f = surfing_nodeidxs2faceidxs(faces');

[coordidx,D,scoords,vORr] = surfing_circleROI(coords',faces',vtx,...
    radius, opts.dismetric, n2f);

end