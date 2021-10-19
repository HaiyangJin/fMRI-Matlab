function [cluVtx, makeupVtx] = sf_makeupcluster(vtxIdx, faces)
% [cluVtx, makeupVtx] = fs_makeupcluster(vtxIdx, hemi, subjCode)
%
% This function fixes the "holes" in the 'vtxIdx'. The vertice that is not 
% in 'vtx' but all its neighboor vertices are in 'vtxIdx' is the "hole".
%
% Inputs:
%    vtxIdx          <integer array> indices of vertices whose areas will
%                     be calculated. Default is all vertices in the label.
%    hemi            <string> 'lh' or 'rh'. Which hemisphere is 'vtxIdx'
%                     from.
%                 OR <numeric array> vertex face array. 
%    subjCode        <string> subject code in struPath. Default is empty.
% 
% Output:
%    cluVtx          <integer vector> all the vertices including 'vtxIdx'
%                     and 'makeupVtx'.
%    makeupVtx       <integer vector> vertex indices of all the "holes".
%
% Created by Haiyang Jin (4-Jun-2020)

% identify the neighbor vertices
nbrVtx = fs_neighborvtx(vtxIdx, faces);

% find all the candidate "hole" vertices, i.e., the unique neighbor
% vertices of 'vtxIdx'
candVtx = setdiff(unique(vertcat(nbrVtx{:})), vtxIdx);

% identify which are the "hole"
isNbrAllIn = arrayfun(@(x) all(ismember(x, vtxIdx)), candVtx);

% the "hole" vertices
makeupVtx = candVtx(isNbrAllIn, 1);

% combine the "hole" with 'vtxIdx
cluVtx = [vtxIdx, makeupVtx];

end