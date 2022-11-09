function outpoints = fs_vtx2mni(vtxIdx, subjCode, surfFn)
% outpoints = fs_vtx2mni(vtxIdx, subjCode, surfFn)
%
% Check the coordinates in MNI152 space for one vertex in self surface
% space.
%
% Inputs:
%    vtxIdx       <int vec> Px1; a list of vertex indices; it should be the 
%                  vertex index in FreeSurfer + 1.
%    subjCode     <str> subject code in $SUBJECTS_DIR.
%    surfFn       <str> the surface used to obtain the coordinates (default
%                  is 'lh.white'. 
% 
% Output:
%    outpoints    <num array> Px3; cooridnates on MNI152.
%
% See 
% Created by Haiyang Jin (2022-Nov-09)
%
% See also:
% fs_vtx2fsavg

if nargin < 1
    fprintf('Usage: outpoints = fs_vtx2mni(vtxIdx, subjCode, surfFn);\n');
    return;
end

if size(vtxIdx,2) ~= 1
    vtxIdx = vtxIdx';
end

if ~exist('surfFn', 'var') 
    surfFn = ''; % default is lh.white in fs_readsurf()
end

% from vtx to fsavg
fsout = fs_vtx2fsavg(vtxIdx, subjCode, surfFn);

% from fsavg to mni152
outpoints = fs_fsavg2mni(fsout);

end