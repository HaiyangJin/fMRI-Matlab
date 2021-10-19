function outVtx = fs_midthickness(subjCode, vtx1, vtx2, ratio, outStr, faces)
% outVtx = fs_midthickness(subjCode, vtx1, vtx2, ratio, outStr, faces)
%
% This function creates the midethickness (or with other ratio) surface file
% of two surfaces (defaults are '?h.white' and '?h.pial'). The name
% 'midthickness' is from HCP workbench. 
%
% Inputs:
%    subjCode      <string> subject code in $SUBJECTS_DIR.
%    vtx1          <string> the surface filename in 'surf/'. Default is
%                   'lh.white'.
%               OR <numeric array> Nx3 matrix. Each row is one vertex and
%                   the three columns are the x,y,z coordiants. 
%    vtx2          similar to 'vtx1', default is 'lh.pial'.
%    ratio         <numeric> the ratio of distance [between output surface
%                   and vtx1 surface] to the distance [between vtx1 and
%                   vtx2 surfaces]. 'ratio' is in range (0, 1). Default is
%                   0.5, i.e., the midthickness surface.
%    outStr        <string> the strings for the output surface filename.
%                   Hemisphere information will be added to 'outStr' if
%                   'vtx1' or 'vtx2' are strings. If outStr is empty,
%                   no output surface file will be saved. (Tips: please
%                   included the hemisphere informatio in 'outStr' if both
%                   'vtx1' and 'vtx2' are numeric array.)
%    faces         <integer array> faces array; necessary for saving the
%                   outSurf if 'vtx1' or 'vtx2' are not surface filenames.
%
% Output:
%    outVtx        <numeric array> Nx3 matrix. Each row is one vertex and
%                   the three columns are the x,y,z coordiants.
%    a output surface file saved in surf/ (if outStr is not empty).
%
% Example:
% outSurf = fs_midethickness('fsaverage', '', '', 0.3, 'white0.3');
%
% Created by Haiyang Jin (10-Oct-2020)

if ~exist('vtx1', 'var') || isempty(vtx1)
    vtx1 = 'lh.white';
end

if ~exist('vtx2', 'var') || isempty(vtx2)
    vtx2 = 'lh.pial';
end

if ~exist('ratio', 'var') || isempty(ratio)
    ratio = 0.5;
else
    assert(ratio >= 0 && ratio <= 1, '''ratio'' has to be in the range(0,1)');
end

if ~exist('outStr', 'var')
    outStr = 'midthickness';
end

if ~exist('faces', 'var')
    faces = [];
end

% process vtx1 and vtx2
[surf1, hemi1, faces1] = vtx2surf(vtx1, subjCode);
[surf2, hemi2, faces2] = vtx2surf(vtx2, subjCode);
assert(size(surf1,1)==size(surf2,1), ...
    'The vertex numbers of the two surfaces do not match.');

% obtain hemisphere information and add to outStr
hemi = unique({hemi1, hemi2});
assert(numel(hemi)==1, ...
    'Please make sure the two surface are for the same hemisphere');

if ~isempty(hemi) && ~isempty(outStr)
    outStr = sprintf('%s.%s', hemi{1}, outStr);
end

% faces
thefaces = {faces1, faces2, faces};
isAva = ~cellfun(@isempty, thefaces);
faces = thefaces{find(isAva,1)};

% calculate the output surface
outVtx = (1-ratio)*surf1 + ratio*surf2;

% save the output surface
if ~isempty(outStr) && ~isempty(faces)
    outFn = fullfile(getenv('SUBJECTS_DIR'), subjCode, 'surf', outStr);
    write_surf(outFn, outVtx, faces);
end

end

function [surf, hemi, faces] = vtx2surf(vtx, subjCode)
% gather inforamtion from vtx1/2
if ischar(vtx)
    hemi = fm_2hemi(vtx);
    [surf, faces] = fs_readsurf(vtx, subjCode);
else
    hemi = '';
    surf = vtx;
    faces = [];
end
end