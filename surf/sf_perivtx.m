function periVtx = sf_perivtx(vtxIdx, faces)
% periVtx = sf_perivtx(vtxIdx, faces)
%
% This function identifies the peripheral (the most outside) vertices of
% 'vtxIdx', which should be contiguous to each other. 
%
% Inputs:
%    vtxIdx          <int array> indices of vertices whose areas will
%                     be calculated. Default is all vertices in the label.
%    hemi            <str> 'lh' or 'rh'. Which hemisphere is 'vtxIdx' from.
%                 OR <num array> vertex face array. 
%    subjCode        <str> subject code in $SUBJECTS_DIR. Default is empty.
%
% Output:
%    periVtx         <int array> the peripheral vertices of 'vtxIdx'.
%
% Created by Haiyang Jin (4-Jun-2020)

% makeup 'vtxIdx' if there is a "hole"
[cluVtx, makeupVtx] = sf_makeupcluster(vtxIdx, faces);
if ~isempty(makeupVtx)
    warning('The "hole" in ''vtxIdx'' is fixed.');
end

% Identify all the neighbor vertices
nbrVtx = sf_neighborvtx(cluVtx, faces);

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