function outpoints = fs_vtx2fsavg(vtxIdx, subjCode, surfFn)
% outpoints = fs_vtx2fsavg(vtxIdx, subjCode, surfFn)
%
% Check the coordinates in fsaverage space for one vertex in self surface
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
%    outpoints    <num array> Px3; cooridnates on fsaverage (MNI305 or MNI
%                  Talairach).
%
% Created by Haiyang Jin (2022-03-11)
%
% See also:
% fs_vtx2mni

if nargin < 1
    fprintf('Usage: outpoints = fs_vtx2fsavg(vtxIdx, subjCode, surfFn);\n');
    return;
end

if size(vtxIdx,2) ~= 1
    vtxIdx = vtxIdx';
end

if ~exist('surfFn', 'var') 
    surfFn = ''; % default is lh.white in fs_readsurf()
end

coords = fs_readsurf(surfFn, subjCode);
inpoints = coords(vtxIdx, :);

% display the input information
fprintf('The input vertex indices are:')
disp(vtxIdx);
fprintf('The coordiantes on the surfaces are:')
disp(inpoints);

outpoints = fs_self2fsavg(inpoints, subjCode);

end