function [nbrVtxExc, nbrVtx] = sf_neighborvtx(vtxIdx, faces, outCell)
% [nbrVtxExc, nbrVtx] = sf_neighborvtx(vtxIdx, hemi, subjCode, outCell)
% 
% This function gathers all the neighbor vertices for each vertex.
%
% Inputs:
%    vtxIdx         <int array> PxQ integer array. Indices of vertices. 
%                    Default is all vertices, which will take fo rever.
%    faces          <str> faces in surface mesh (triangles).
%    outCell        <boo> 1 [default]: save the output as cell. 0: save
%                    the output as integer vector if possible.
%
% Output:
%    nbrVtxExc      <int cell> PxQ cell array. each cell is the 
%                    neighborhood vertices for that corresponding vertex 
%                    in vtxIdx.
%                or <int vector> the neighbor vertices for nbrVtxExc. 
%    nbrVtx         <int cell> PxQ cell array. each cell is the 
%                    neighborhood vertices and that corresponding vertex 
%                    in vtxIdx.
%                or <int vector> the neighbor vertices for vtxIdx.
%
% Created by Haiyang Jin (2021-10-19)
%
% See also:
% fs_neighborvtx

%% Deal with inputs
if ~exist('outCell', 'var') || isempty(outCell)
    outCell = 1;
end

% use all vertices by default
if ~exist('vtxIdx', 'var') || isempty(vtxIdx)
    vtxIdx = unique(faces(:)');
    warning('All vertices are used by default and it will take forever...');
end

% obtain the neighbor vertices
nbrVtx = arrayfun(@(x) neighborvtx(faces, x), vtxIdx, 'uni', false);
nbrVtxExc = cellfun(@(x, y) setdiff(x, y), nbrVtx, num2cell(vtxIdx), 'uni', false);

% save the output as a vector if needed
if ~outCell && numel(nbrVtx) == 1
    nbrVtx = nbrVtx{1};
    nbrVtxExc = nbrVtxExc{1};
end

end

%% obtain the neighbor vertices for single vertex
function uniqueVtx = neighborvtx(faces, vtx)

% find faces consisting of vtx
containVtx = any(faces==vtx, 2);

% keep the unique vertices
uniqueVtx = unique(faces(containVtx, :));

end