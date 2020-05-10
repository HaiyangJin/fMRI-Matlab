function nbrVtx = fs_neighborvtx(vtxIdx, hemi, subjCode, outCell)
% nbrVtx = fs_neighborvtx(vtxIdx, hemi, subjCode, outCell)
% 
% This function gathers all the neighbor vertices for each vertex.
%
% Inputs:
%    vtxIdx         <integer array> PxQ integer array. Indices of vertices. 
%                    Default is all vertices, which will take fo rever.
%    hemi           <string> 'lh' or 'rh'. 
%    subjCode       <string> subject code in $SUBJECTS_DIR.
%    outCell        <logical> 1 [default]: save the output as cell. 0: save
%                    the output as integer vector if possible.
%
% Output:
%    nbrVtx         <integer cell> PxQ cell array. each cell is the 
%                    neighborhood vertices for that corresponding vertex 
%                    in vtxIdx.
%                or <integer vector> the neighbor vertices for vtxIdx.
%
% Created by Haiyang Jin (10-May-2020)

%% Deal with inputs
if ~exist('subjCode', 'var') || isempty(subjCode)
    subjCode = 'fsaverage';
    warning('''%s'' is used as ''subjCode'' by default.', subjCode);
end
if ~exist('outCell', 'var') || isempty(outCell)
    outCell = 1;
end

if ~exist('hemi', 'var') || isempty(hemi)
    hemi = 'lh';
    warning('''%s'' is used as ''hemi'' by default.', hemi);
end
% load faces
[~, faces] = fs_readsurf([hemi '.white'], subjCode);

% use all vertices by default
if ~exist('vtxIdx', 'var') || isempty(vtxIdx)
    vtxIdx = unique(faces(:)');
    warning('All vertices are used by default and it will take forever...');
end

% obtain the neighbor vertices
nbrVtx = arrayfun(@(x) neighborvtx(faces, x), vtxIdx, 'uni', false);

% save the output as a vector if needed
if ~outCell && numel(nbrVtx) == 1
    nbrVtx = nbrVtx{1};
end

end

%% obtain the neighbor vertices for single vertex
function uniqueVtx = neighborvtx(faces, vtx)

% find faces consisting of vtx
containVtx = any(faces==vtx, 2);

% keep the unique vertices
uniqueVtx = unique(faces(containVtx, :));

end