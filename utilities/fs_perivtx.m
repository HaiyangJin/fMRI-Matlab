function periVtx = fs_perivtx(vtxIdx, hemi, subjCode)
% periVtx = fs_perivtx(vtxIdx, hemi, subjCode)
%
% This function identifies the peripheral (the most outside) vertices of
% 'vtxIdx', which should be contiguous to each other. 
%
% Inputs:
%    vtxIdx          <integer array> indices of vertices whose areas will
%                     be calculated. Default is all vertices in the label.
%    hemi            <string> 'lh' or 'rh'. Which hemisphere is 'vtxIdx'
%                     from.
%    subjCode        <string> subject code in struPath. Default is empty.
%
% Output:
%    periVtx         <integer array> the peripheral vertices of 'vtxIdx'.
%
% Created by Haiyang Jin (4-Jun-2020)

% makeup 'vtxIdx' if there is a "hole"
[cluVtx, makeupVtx] = fs_makeupcluster(vtxIdx, hemi, subjCode);
if ~isempty(makeupVtx)
    warning('The "hole" in ''vtxIdx'' is fixed.');
end

% Identify all the neighbor vertices
nbrVtx = fs_neighborvtx(cluVtx, hemi, subjCode);

% check if each of the neighbor vertices is in 'vtxIdx'
inVtxCell = cellfun(@(x) ismember(x, cluVtx), nbrVtx, 'uni', false);

% identify the vertices whose all neighbor vertices is in 'vtxIdx'
% these vertices will be the "inner" vertices
isInVtx = cellfun(@all, inVtxCell);

% identify the peripheral vertices
periVtx = cluVtx(~isInVtx);

% make sure the 'periVtx' does not share vertices with 'makeupVtx'
assert(isempty(intersect(periVtx, makeupVtx)));

end